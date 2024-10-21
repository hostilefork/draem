Rebol [
    Title: "Takes input in the Draem dialect and produces HTML"
    File: %htmlify.reb
]


begin-span-or-div: function [
    is-span [logic!]
    class [word!]
][
    combine [
        "<"
            (either is-span ["span"] ["div"])
            space
            -{class="}- to text! class -{"}-
        ">"
    ]
]


end-span-or-div: function [
    is-span [logic!]
][
    combine ["</" (either is-span ["span"] ["div"]) ">"]
]


last-append: null

htmlify: function [
    "Recursively produce HTML for a Draem Rebol structure"
    blk -{Legal to be [[quote "Some text"]], but not [quote "Some text"]}-
        [block!]
    /nestfirst
    /nestlast
    /span
    <with> last-append
][
    span: to logic! span

    ;-- Review proposals for constructors...
    result: make text! 1000

    append-result: func [html [text!]] [
        append result html
        last-append: html
        return ~
    ]

    segment-rule: [
        ;-- FEEDER
        ;-- we only do this for PRINT now.  Lest would generalize it.
        ['print '<< paragraphs: block!] (
            for-each str paragraphs [
                append-result combine [
                    (begin-span-or-div span 'exposition) newline
                    markdown str
                    (end-span-or-div span) newline
                ]
            ]
        )
    |
        ;-- STRING
        ;-- Strings bottom out as being handled by markdown.  If a string
        ;-- starts a block, it's expected that the block is going to be
        ;-- a group of elements; hence there are no parameters.
        ['print str: text!] (
            append-result combine [
                (begin-span-or-div span 'exposition) newline
                markdown str
                (end-span-or-div span) newline
            ]
        )
    |
        ;-- DIVIDER
        ;-- Puts in a horizontal line element.
        ['divider] (
            append-result combine [<hr> newline]
        )
    |
        ;-- SEPARATOR
        ;-- Adds some spacing, but no line.
        ['separator] (
            append-result combine [<span> "&nbsp;" <br /> </span> newline]
        )
    |
        ;-- URL
        ;-- Can be either lone URL, or block with URL and anchor label.
        ;-- If lone URL, the URL is used as the anchor text also.
        [
            ['link url: url!] (
                anchor-text: to text! url
            )
        |
            ['link ahead block! into [
                [url: url!]
                [anchor-text: text!]
                <end>
            ]]
        ] (
            ;-- put in better url encoding logic or decide what should be done
            replace url "&" "&amp;"

            append-result combine [
                (begin-span-or-div span 'url) newline
                -{<a href="}- url -{">}-
                anchor-text
                </a>
                (end-span-or-div span) newline
                newline
            ]
        )
    |
            ;-- PICTURE
            ;-- Hack for dream journal, need to revisit a generalized
            ;-- site-wide way of locating media.  See also IMAGE.
            [
                'picture
                picture-file: file!
            ] (

                append-result combine [
                    <div class="picture">
                    -{<a href="http://realityhandbook.org/media/entries/}-
                    to text! picture-file
                    -{">}-

                    -{<img src="http://realityhandbook.org/media/entries/}-
                    to text! picture-file
                    -{">}-
                    </a>
                    </div>
                    newline
                ]
            )
        |
            ;-- IMAGE
            ;-- See also PICTURE (hack)
            ['image ahead block! into [
                [url: url!]
                [size: pair!]
                [caption: text!]
                <end>
            ]] (
                append-result combine [
                    <div class="picture">
                    -{<a href="}- url -{">}-
                        -{<img src="}- url -{"}- space
                        -{alt="}- caption -{"}- space
                        -{width="}- to integer! size.1 -{"}- space
                        -{height="}- to integer! size.2 -{" />}-
                    </a>
                    </div>
                ]
            )
        |
            ;-- BUTTON
            ['button ahead block! into [
                [image-url: url!]
                [size: pair!]
                [caption: text!]
                [link-url: url!]
                <end>
            ] (
                append-result combine [
                    <div class="picture">
                    -{<a href="}- to text! link-url -{">}-
                        -{<img src="}- to text! image-url -{"}- space
                        -{alt="}- caption -{"}- space
                        -{width="}- to integer! size.1 -{"}- space
                        -{height="}- to integer! size.2 -{" />}-
                    </a>
                    </div>
                ]
            )
        |
            ;-- QUOTE
            ['quote args: [text! | block!]] (
                append-result combine [
                    <blockquote>

                    either text? args [
                        [
                            begin-span-or-div true 'exposition newline
                            markdown args
                            end-span-or-div true newline
                        ]
                    ][
                        htmlify args
                    ]

                    </blockquote>

                    newline
                ]
            )
        |
            ['attribution url: url!] (
                ;-- http://html5doctor.com/blockquote-q-cite/
                append-result combine [
                    <footer> -{<a href="}- url -{">}- url -{/a>}- </footer>
                ]
            )
        |
            ['attribution str: text!] (
                ;-- http://html5doctor.com/blockquote-q-cite/
                append-result combine [
                    <footer> markdown str </footer>
                ]
            )
        |
            ['attribution arg: block!] (
                ;-- http://html5doctor.com/blockquote-q-cite/
                append-result combine [
                    <footer> htmlify:span arg </footer>
                ]
            )
        |
            ['attribution str: text!] (
                ;-- http://html5doctor.com/blockquote-q-cite/
                append-result combine [
                    <footer>
                    (begin-span-or-div span 'exposition) newline
                    markdown str
                    (end-span-or-div span) newline
                    </footer>
                ]
            )
        |
            ;-- NOTE and UPDATE
            [
                ['note (is-note: true) | 'update (is-note: false)]
                (date: null) opt [date: date!]
                args: [block! | text!]
            ] (
                append-result combine [
                    -{<div class="}- (either is-note ["note"] ["update"]) -{">}-
                    either is-note [
                        [<span class="note-span"> -{Note}- </span>]
                    ][
                        [
                            <span class="update-span"> -{UPDATE}-
                            if date [
                                [space date]
                            ]
                            </span>
                        ]
                    ]
                    space
                    either text? args [
                        combine [
                            (begin-span-or-div true 'exposition) newline
                            markdown args
                            (end-span-or-div true) newline
                        ]
                    ][
                        either 1 = length? args [
                            htmlify:span args
                        ][
                            htmlify args
                        ]
                    ]
                    </div>
                    newline
                ]
            )
        |
            ;-- CODE, TEXT, ERROR
            [
                'source
                (language: null) opt [language: lit-word!]
                [code: text!]
            ] (
                language: if language [to-word language]

                if language = 'text [
                    language: null
                ]

                ;-- Current markup is expected to be HTML compatible
                ;-- http://stackoverflow.com/a/13010144/211160
                replace code "&" "&amp;" ;-- ampersand has to be first, or you double escape!
                replace code "<" "&lt;"
                replace code ">" "&gt;"

                trim-head-tail-lines code

                needs-pre-tag: language <> 'error
                needs-code-tag: language <> null

                ;-- TODO: work out the right language classes for google code prettify
                ;-- http://stackoverflow.com/q/11742907/211160
                append-result combine [
                    if needs-pre-tag [
                        [
                            -{<pre}-
                            if all [
                                language
                            ][
                                [
                                    space
                                    -{class="prettyprint}-
                                    space "lang-" to text! language
                                    -{"}-
                                ]
                            ]
                            -{>}-
                        ]
                    ]
                    (if needs-code-tag [<code>])
                    code
                    (if needs-code-tag [</code>])
                    (if needs-pre-tag [</pre>])
                    newline
                ]
            )
        |
            ;-- HEADING
            [
                'heading
                (anchor: null) opt [anchor: file!]
                heading-text: text!
            ] (
                append-result combine [
                    if anchor [
                        ; http://stackoverflow.com/a/484781/211160
                        [-{<a id="}- to text! anchor -{">}- </a>]
                    ]
                    <h3> markdown heading-text </h3>
                    newline
                ]
            )
        |
            ;-- LIST
            [
                'list ahead block! into [
                    'item '<< args: block!
                ]
            ] (
                ;-- First I tried using map-each
                ;-- If we return a block and do not compose elem first,
                ;-- then elem will be evaluated incorrectly.  Review
                ;-- the precise problem with doing this...

                append-result combine [<ul> newline]

                for-each elem args [
                    append result combine [
                        <li>
                        either text? elem [
                            [
                                begin-span-or-div false 'exposition newline
                                markdown elem
                                end-span-or-div false newline
                            ]
                        ][
                            either word? elem [
                                htmlify reduce [elem]
                            ][
                                htmlify elem
                            ]
                        ]

                        </li>
                        newline
                    ]
                ]

                append-result combine [</ul> newline]
            )
        |
            ;-- HTML
            [
                'html
                html: text!
            ] (
                ;-- The HTML construct should probably be more versatile, but
                ;-- for the moment let's just limit it to one HTML string
                append-result html
            )
        |
            ;-- YOUTUBE
            [
                'youtube
                ahead block! into [
                    [url: url!]
                    [size: pair!]
                ]
            ] (
                ;-- I like the idea of being able to put actual working youtube URLs in
                ;-- without having to extract the stupid ID, so I can just click on the
                ;-- video from the source I'm writing.

                ;-- But revisit what's tolerated and what isn't
                if not all [
                    parse to text! url [
                        ["http" [opt "s"] "://" [opt "www."] "youtube.com/v/" video-id: across to [<end> | "?"]]
                    |
                        ["http" [opt "s"] "://" [opt "www."] "youtube.com/watch" thru "v=" video-id: across to [<end> | "#"]]
                    |
                        ["http" [opt "s"] "://" [opt "www."] "youtube.com/embed/" video-id: across to [<end> | "#"]]
                    ]
                ][
                    fail "Bad youtube embed"
                ]

                ;-- http://www.webupd8.org/2010/07/embed-youtube-videos-in-html5-new.html
                ;-- http://www.gtpdesigns.com/design-blog/view/w3c-valid-xthml-and-html5-youtube-iframe-embeds

                append-result combine [
                    <div class="youtube">
                        -{<iframe class="youtube-player"}- space

                        ;-- Conversion needed as first 10x20 returns 10.0 :-/
                        -{width="}- to integer! size.1 -{"}- space
                        -{height="}- to integer! size.2 -{"}- space
                        -{src="https://www.youtube.com/embed/}- video-id -{"}- space
                        -{allowFullScreen}-
                        -{>}-
                        </iframe>
                    </div>
                ]
            )
        ]
    |
        ;-- DIALOGUE
        ;-- Dialogue is a special case which requires a block, there is no
        ;-- standalone legal "set-word".  The unusual nature of the dialogue
        ;-- challenges a generalized system, yet shows great value of a
        ;-- dialect... and handling this case points a direction to what
        ;-- Rebol does that systems like Django/Rails cannot.
        'dialog and block! into [
            some [
                [character: set-word!]
                (parenthetical: null)
                opt [parenthetical: tag!]
                [dialogue-text: text!]
                (
                    append-result combine [
                        begin-span-or-div span 'dialogue

                        <span class="character"> stringify character </span> ":" space
                        if parenthetical [
                            [
                                <span class="action">
                                "(" to text! parenthetical ")"
                                </span> space
                            ]
                        ]

                        -{"}- markdown dialogue-text -{"}-

                        end-span-or-div span
                    ]
                )
            ]
        ]
    ]

    if not parse:match blk [opt some [pos: <here>, segment-rule]] [
        print "INVALID DRAEM DATA - PARSE RETURNED FALSE"
        print mold pos
        print "LAST APPEND WAS"
        print mold last-append
        quit 1
    ]

    assert [text? result]  ; may be empty
    return result
]


htmlify-range: function [
    "Consider blocks as groups (unlike HTMLIFY treating blocks as elements)"

    start [block!]
    end [block!]
][
    assert [(head start) = (head end)]
    assert [1 <= offset? start end]

    result: copy ""
    pos: start
    while [pos <> end] [
        ;-- htmlify always expects a block of elements
        blk: append:only copy [] first pos
        protect blk

        case [
            all [
                end = next pos
                start = pos
            ][
                append result htmlify:nestfirst:nestlast blk
            ]
            start = pos [
                append result htmlify:nestfirst blk
            ]
            end = next pos [
                append result htmlify:nestlast blk
            ]
            true [
                append result htmlify blk
            ]
        ]
        pos: next pos
    ]
    return result
]

htmlify-group: function [
    blk [block!]
][
    assert [blk = head blk]
    htmlify-range blk (tail blk)
]
