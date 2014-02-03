rebol [
	Title: "Common Draem Routines"
	Description: {

	Common definitions included by all the Draem modules.

	}

	Home: http://realityhandbook.org/
	License: 'mit

	Date: 20-Oct-2010
	Version: 0.3.0.4

	; Header conventions: http://www.rebol.org/one-click-submission-help.r
	File: %common.reb
	Type: 'dialect
	Level: 'intermediate
]


;---
; Bridge TO and FUNCTION behavior for which there are pull requests,
; but not integrated into the mainline yet.
;---

function: :funct

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
	] [
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
	change/part code (rejoin code-lines) tail code
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
    ] [
        foreach file files [delete-dir dir/:file]
    ] 
    attempt [delete dir]
]


prompt-delete-dir-if-exists: function [
	dir [file!]
] [
	if exists? dir [
		print [{Directory} dir {currently exists.}]
		either "Y" = uppercase ask "Delete it [Y/N]?" [
			delete-dir dir
		] [
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
	] [
		replace/all to string! word "-" space
	]
]

comma-separated: function [
	block [block!] 
	/callback strfunc [function!] 
] [
	if (empty? block) [
		return {}
	]
	result: copy {}
	foreach elem block [
		append result either callback [strfunc elem] [elem]
		append result rejoin [{,} space]
	]
	remove/part back back tail result 2
	return result
]

url-for-entry: function [entry [object!]] [
	;-- Required hook: produce URL from header
	assert [function? :draem/config/url-from-header]

	draem/config/url-from-header entry/header
]

link-to-entry: func [entry [object!]] [
	rejoin [
		open-anchor url-for-entry entry
		entry/header/title
		close-anchor
		space {:} space to string! replace/all copy to string! entry/header/date/date {0:00} {}
		{<br />}
	]
]
