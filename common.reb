rebol [
    Title: "Common Draem Routines"
    Description: {
        Common definitions included by all the Draem modules.
    }

    Home: http://draem.hostilefork.com
    License: 'mit

    Date: 20-Oct-2010
    Version: 0.3.0.4

    ; Header conventions: http://www.rebol.org/one-click-submission-help.r
    File: %common.reb
    Type: 'dialect
    Level: 'intermediate
]


;---
; Bridge TO behavior for which there are pull requests, but not integrated
; into the mainline yet.
;---

unless value? 'old-to [
    old-to: :to
]

to: func [type value] [
    if any [string! == type  string! == type? type] [
        if any-word? value [
            return replace/all replace/all replace/all old-to string! value {:} {} {'} {} {/} {}
        ]
    ]
    return old-to type value
]


;---
; If keys are mapped to blocks in a map, return a block variant of that
; map sorted in order of the longest blocks first
;---
make-sorted-block-from-map: function [map [map!]] [
    blk: split make block! map 2
    sort/compare blk func [a b] [(length? second a) > (length? second b)]
    pos: head blk
    while [not tail? pos] [
        pos: change/part pos first pos 1
    ]
    return blk
]

;--
; Small helper for getting an object field as a block; if the
; field does not exist then it will be an empty block, and if
; it isn't a block it will be put into one.
;--

in-as-block: func [obj [object!] key [word!]] [
    either in obj key [
        either block? obj/(key) [obj/(key)] [reduce [obj/(key)]]
    ][
        []
    ]
]

;--
; We want to trim head and tail lines from code, but not tabs or spaces
;--
trim-head-tail-lines: function [code [string!]] [
    ;-- Trim empty lines on top or bottom
    ;-- (they might make the source easier to read)
    code-lines: split code lf
    while ["" = trim copy first code-lines] [
        take code-lines
    ]
    while ["" = trim copy last code-lines] [
        take/last code-lines
    ]
    foreach line code-lines [
        append line lf
    ]
    change/part code (combine code-lines) tail code
    exit
]



;---
; Delete directory function from:
; http://en.wikibooks.org/wiki/REBOL_Programming/delete-dir
;---

delete-dir: func [
    {Deletes a directory including all files and subdirectories.}
    dir [file! url!]
    /local files
][
    if all [
        dir? dir
        dir: dirize dir
        attempt [files: load dir]
    ][
        foreach file files [delete-dir dir/:file]
    ]
    attempt [delete dir]
]


prompt-delete-dir-if-exists: function [
    dir [file!]
][
    if exists? dir [
        print [{Directory} dir {currently exists.}]
        either "Y" = uppercase ask "Delete it [Y/N]?" [
            delete-dir dir
        ][
            quit
        ]
    ]
]


;---
; Helper routines for generating templates etc.
;---

; converts slug, character, or tag to a string with option to have dashes
; or spaces (default)
stringify: func [word [set-word! word! file! string!] /dashes] [
    if string? word [
        print ["already stringified:" word]
        quit
    ]

    either dashes [
        to string! word
    ][
        replace/all to string! word "-" space
    ]
]

url-for-entry: function [entry [object!]] [
    ;-- Required hook: produce URL from header
    assert [action? draem.config.url-from-header/]

    draem.config/url-from-header entry.header
]

link-to-entry: function [entry [object!]] [
    combine [
        {<a href="} url-for-entry entry {">}
        entry.header.title
        </a>
        space {:} space to string! replace/all copy to string! entry.header.date.date {0:00} {}
        <br />
    ]
]

flatten: func [
    data
    /local rule
][
    local: make block! length? data
    rule: [
        into [some rule]
    |
        set value skip (append local value)
    ]
    parse data [some rule]
    local
]

; The COMBINE dialect is intended to assist with the common task of creating
; a merged string series out of component Rebol values.  Its
; goal is to be friendlier than REJOIN, and to hopefully become the
; behavior backing PRINT.
;
; Currently in a proposal period, and there are questions about whether the
; same dialect can be meaningful for blocks or not.
;
; http://blog.hostilefork.com/combine-alternative-rebol-red-rejoin/
;
combine: func [
    block [block!]
    /with "Add delimiter between values (will be COMBINEd if a block)"
        delimiter [block! any-string! char! any-function!]
    /into
        out [any-string!]
    /local
        needs-delimiter pre-delimit value temp
    ; hidden way of passing depth after /local, review...
    /level depth
][
    ;-- No good heuristic for string size yet
    unless into [
        out: make string! 10
    ]

    unless any-function? :delimiter [
        unless block? delimiter [
            delimiter: compose [(delimiter)]
        ]
        delimiter: func [depth [integer!]] compose/only/deep [
            combine (delimiter)
        ]
    ]

    unless depth [
        depth: 1
    ]

    needs-delimiter: false
    pre-delimit: does [
        either needs-delimiter [
            set/any 'temp delimiter depth
            if all [
                value? 'temp
                (not null? temp) or (block? out)
            ][
                out: append out temp
            ]
        ][
            needs-delimiter: true? with
        ]
    ]

    ;-- Do evaluation of the block until a non-null evaluation result
    ;-- is found... or the end of the input is reached.
    while [not tail? block] [
        set/any 'value do/next block 'block

        ;-- Blocks are substituted in evaluation, like the recursive nature
        ;-- of parse rules.

        case [
            unset? :value [
                ;-- Ignore unset! (precedent: any, all, compose)
            ]

            any-function? :value [
                do make error! "Evaluation in COMBINE gave function/closure"
            ]

            block? value [
                pre-delimit
                out: combine/with/into/level value :delimiter out depth + 1
            ]

            ; This is an idea that was not met with much enthusiasm, which was
            ; to allow COMBINE ['X] to mean the same as COMBINE [MOLD X]
            ;any [
            ;    word? value
            ;    path? value
            ;] [
            ;    pre-delimit ;-- overwrites temp!
            ;    temp: get value
            ;    out: append out (mold :temp)
            ;]

            refinement? value [
                case [
                    value = /+ [
                        needs-delimiter: false
                    ]

                    true [
                        do make error! "COMBINE refinement other than /+ used"
                    ]
                ]
            ]

            any-block? value [
                ;-- all other block types as *results* of evaluations throw
                ;-- errors for the moment.  (It's legal to use PAREN! in the
                ;-- COMBINE, but a function invocation that returns a PAREN!
                ;-- will not recursively iterate the way BLOCK! does)
                do make error! "Evaluation in COMBINE gave non-block! or path! block"
            ]

            any-word? value [
                ;-- currently we throw errors on words if that's what an
                ;-- evaluation produces.  Theoretically these could be
                ;-- given behaviors in the dialect, but the potential for
                ;-- bugs probably outweighs the value (of converting implicitly
                ;-- to a string or trying to run an evaluation of a non-block)
                do make error! "Evaluation in COMBINE gave symbolic word"
            ]

            null? value [
                ;-- Skip all nones
            ]

            true [
                pre-delimit
                out: append out (form :value)
            ]
        ]
    ]
    either into [out] [head out]
]
