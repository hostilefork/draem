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

fake-category: function [
	{Some categories like ABOUT and CONTACT aren't really for entries, but
	for pages formatted in a similar way.  They should not be shown in 
	lists and should direct to top-level templates, e.g. %templates/about.html}

	category [word!]
] [
	find [about contact] category 
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
