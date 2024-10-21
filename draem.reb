Rebol [
    Title: "Draem"
    Description: --{
        This is the main module for the static website builder known as
        Draem.  Currently it implements loading of entries and the
        indexing of those entries.  The goal will be to also provide
        hooks for reusing the loader and then "munging" the entries
        to rewrite them using arbitrary meta-programming.
    }--

    Home: http://draem.hostilefork.com
    License: 'mit

    Date: 13-Jan-2014
    Version: 0.4

    ; Header conventions: http://www.rebol.org/one-click-submission-help.r
    File: %make-site.reb
    Type: 'dialect
    Level: 'intermediate

    Usage: --{
       Current usage is just to run this script in the directory containing
       %entries/ and it will spit out a directory called %templates/
    }--
]

do %common.reb

do %make-templates.reb
do %make-timeline.reb
do %make-atom-feed.reb

draem: context [

    ;-- Site configuration, defaults to null
    config: null

    set-config: func [
        "Do validation on the site configuration, and set it"

        cfg [object!]
    ][
        assert [null? config]
        assert [all [
            ;-- Required properties
            text? cfg.site-name
            url? cfg.site-url
            dir? cfg.entries-dir
            dir? cfg.templates-dir
            block? cfg.site-toplevel-slugs

            ;-- Required hooks
            action? cfg.url-from-header/
            action? cfg.file-for-template/

            ;-- Optional hooks
            either in cfg 'check-header [
                action? cfg.check-header/
            ][
                true
            ]
        ]]

        config: cfg
    ]


    ;-- Block of entries sorted by reverse date, defaults to null
    entries: null

    ;-- a map that remembers where each entry was originally loaded from
    slug-to-source-path: make map! []

    set-entries: func [
        "Sets the entries block in this context, assumed valid"

        ent [block!]
    ][
        assert [null? entries]
        entries: ent
    ]


    indexes: null

    set-indexes: func [
        "Sets the index information in this context, assumed valid"

        idx [object!]
    ][
        assert [null? indexes]
        indexes: idx
    ]


    stage: function [
        "Log what stage we are in"
        name [text!]
    ][
        print [lf "===" name "==="]
    ]


    load-entries: function [
        "Recursively load all entries into reverse-chronological block"

        /recurse sub-dir [file!] entries [block!]
    ][
        print ["Entering load entries with" reify sub-dir]
        if not recurse [
            stage "LOADING ENTRIES"

            ; entries list sorted newest first, oldest last
            entries: copy []
            sub-dir: to file! ""
        ]

        for-each file load (join config.entries-dir sub-dir) [
            either dir? file [
                print ["Recursing into:" rejoin [config.entries-dir sub-dir file]]
                load-entries:recurse (join sub-dir file) entries
            ][
                print ["Pre-processing:" file]

                data: read rejoin [config.entries-dir sub-dir file]

                if find data #{C2A0} [
                    fail "Non-breaking space found.  Get rid of it."
                ]

                data: load data

                pos: data

                if not all [
                    'Draem == first pos
                    elide pos: my next
                    block? first pos
                ][
                    fail "Entry must start with Draem header"
                ]

                header: make object! first pos
                pos: my next

                if not all [
                    in header 'date
                    date? header.date
                ][
                    fail "Header requires valid date field"
                ]

                if not all [
                    in header 'slug
                    file? header.slug
                ][
                    fail "Header requires a file! slug field"
                ]

                if not all [
                    in header 'title
                    text? header.title
                ][
                    fail "Header requires a text! title field"
                ]

                if not all [
                    in header 'tags
                    block? header.tags
                    does [for-each tag header.tags [if not word? tag return false] true]
                ][
                    fail "Header requires a tags block containing words"
                ]

                if in config 'check-header [
                    config/check-header header
                ]

                entry: make object! compose:only [
                    header: (header)
                    content: (copy pos)
                ]

                append slug-to-source-path reduce [
                    entry.header.slug
                    rejoin [sub-dir file]
                ]

                ;-- Hacky
                if not find header.tags 'draft [
                    append entries entry
                ]
            ]
        ]

        sort:compare entries func [a b] [a.header.date > b.header.date]

        if not recurse [
            set-entries entries
        ]

        return ~
    ]

    ;-- Next and previous entry logic; slow and bad

    previous-entry: function [header [object!]] [
        if find config.site-toplevel-slugs header.slug [
            return null
        ]

        pos: entries
        while [not tail? pos] [
            if pos.1.header = header [
                pos: next pos
                while [
                    all [
                        not tail? pos
                        find config.site-toplevel-slugs pos.1.header.slug
                    ]
                ][
                    pos: next pos
                ]
                return first pos
            ]
            pos: next pos
        ]
        assert [false]
    ]

    next-entry: function [header [object!]] [
        if find config.site-toplevel-slugs header.slug [
            return null
        ]

        result: null
        pos: entries
        while [not tail? pos] [
            if pos.1.header = header [
                return result
            ]
            if not find config.site-toplevel-slugs pos.1.header.slug [
                result: pos.1
            ]
            pos: next pos
        ]
        assert [false]
    ]


    do-nulyne: function [
        blk [any-list!]
    ][
        for-each elem blk [
            case [
                any-list? elem [do-nulyne elem]
                text? elem [replace elem "^/" "^/NULYNE"]
            ]
        ]
    ]

    save-entries: function [
        target-dir [file!]
    ][
        prompt-delete-dir-if-exists target-dir

        for-each entry entries [
            target-file: rejoin [target-dir (select slug-to-source-path entry.header.slug)]
            make-dir:deep split-path target-file

            out: copy "Draem "

            for-each w words-of entry.header [
                if word? select entry.header w [
                    entry.header.(w): to lit-word! select entry.header w
                ]
            ]

            append out mold body-of entry.header
            append out "^/^/"

            do-nulyne entry.content
            content-string: mold:only entry.content

            pos: content-string
            while [not tail? pos] [
                if #"^/" = first pos [
                    if "^/NULYNE" <> copy/part pos 7 [
                        insert pos "^/"
                        pos: my next
                    ]
                ]
                pos: my next
            ]
            replace content-string "^/NULYNE" "^/"

            append out content-string
            append out "^/"

            write target-file out
        ]
    ]

    entry-tags-by-popularity: function [
        "Return the tags as a block sorted by popularity"
        header [object!]
    ][
        sorted-tags: copy header.tags
        sort:compare sorted-tags func [a b] [
            (length? indexes.tag-to-entries.(a)) >
            (length? indexes.tag-to-entries.(b))
        ]
    ]

    build-indexes: function [
        "Build indexing information over the entries block"
    ][
        stage "BUILDING INDEXES"

        indexes: make object! [
            ; map from tags to list of entries with that tag
            tag-to-entries: make map! []

            ; map from character to list of entries where they appear
            character-to-entries: make map! []

            ; map from entry slug to the characters list appearing in it
            slug-to-characters: make map! []

            ; map from entry slug to the entry itself
            slug-to-entry: make map! []
        ]

        for-each entry entries [
            repend indexes.slug-to-entry [entry.header.slug entry]

            header: entry.header
            content: entry.content

            for-each tag header.tags [
                either select indexes.tag-to-entries tag [
                    append select indexes.tag-to-entries tag entry
                ][

                    append indexes.tag-to-entries compose:deep copy:deep [(tag) [(entry)]]
                ]
            ]

            ; collect the characters from blocks beginning with set-word in the body
            characters: copy []
            repend indexes.slug-to-characters [entry.header.slug characters]

            collect-characters: function [blk [block!]] [
                dialog-rule: [
                    some [
                        who: set-word! (
                            if not find characters to-word who [
                                append characters to-word who
                            ]
                        )
                    |
                        one
                    ]
                ]

                rule: [opt some [
                    'dialog ahead block! into dialog-rule
                |
                    ahead block! into rule
                |
                    one
                ]]

                parse blk rule
            ]

            collect-characters content

            for-each character characters [
                either select indexes.character-to-entries character [
                    append select indexes.character-to-entries character entry
                ][
                    append indexes.character-to-entries compose:deep copy:deep [(character) [(entry)]]
                ]
            ]
        ]

        set-indexes indexes
    ]


    make-site: function [] [

        ;-- User must set the draem configuration before calling
        assert [object? config]

        err: catch [

            ;-- Clients may have loaded the entries prior for analysis
            if not entries [load-entries]
            if not indexes [build-indexes]

            prompt-delete-dir-if-exists config.templates-dir

            make-templates entries indexes config.templates-dir

            make-timeline entries (join config.templates-dir %timeline.xml)

            make-atom-feed entries (join config.templates-dir %atom.xml) 20

            null
        ]

        if err [
            print form err
        ]

        return ~
    ]
]
