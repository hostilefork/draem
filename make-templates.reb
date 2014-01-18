Rebol [
	Title: "Make Django Templates"
	Description: {

	Currently the way the realityhandbook website works is that there is
	no database, just a bunch of templates... one generated for each
	article, and then for each tag + category + character.  These 
	templates participate in Django's inheritance model... so each one
	adds its content to a baseline template without repeating the
	boilerplate.

	}

	Home: http://realityhandbook.org/
	License: 'mit

	Date: 20-Oct-2010
	Version: 3.0.4

	; Header conventions: http://www.rebol.org/one-click-submission-help.r
	File: %make-templates.reb
	Type: 'dialect
	Level: 'intermediate
]

do %common.reb

django-block: func [name [string!] stuff [block!] /inline] [
	result: compose [
		(rejoin ["{% block" space name space "%}"])
		(reduce stuff)
		(rejoin ["{% endblock" space name space "%}"])
	]
	if inline [
		result: reduce [rejoin result]
	]
	append result {}
]

django-path: func [stuff [block!] ] [
	django-block "path" compose [
		{<li>
			<a href="} draem/config/site-url {" title="Home">Home</a>
		</li>}
		(stuff)
		{}
	]
]

django-extends: func [template [file!]] [
	compose [
		(rejoin ["{% extends" space {"} to string! template {"} space "%}"])
		{}
	]	
]

open-anchor: func [url [url!]] [
	rejoin [{<} {a} space {href} {=} {"} to string! url {"} {>}]
]

close-anchor: {</a>}

link-to-category: func [category [word!] /count num] [
	rejoin [
		open-anchor rejoin [
			draem/config/site-url {category/}
			stringify/dashes category 
			{/}
		]
		stringify category
		close-anchor
		space {:} space num {<br />}
	]

]

link-to-tag: func [tag [word!] /count num] [
	rejoin [
		open-anchor rejoin [
			draem/config/site-url "tag/" stringify/dashes tag {/}
		]
		stringify tag
		close-anchor
		space {:} space num {<br />}
	]
]

link-to-character: func [character [word!] /count num] [
	rejoin [
		open-anchor rejoin [
			draem/config/site-url "character/" stringify/dashes character {/}
		]
		stringify character
		close-anchor
		space {:} space num {<br />}
	]
]


;-- Very hacky and limited markdown-to-html rendering
dream-markup: function [str [string!]] [
	result: copy str

	pos: result
	while [pos: find pos {&}] [
		unless #"#" = second pos [
			replace pos "&" "&amp;"
		]
		++ pos
	]

	replace/all result ">" "&gt;"
	replace/all result "<" "&lt;"

	pos: result
	while [pos: find pos {**}] [
		replace pos {**} {<b>}
		replace pos {**} {</b>}
	]

	pos: result
	while [pos: find pos {*}] [

		unless space = second pos [
			pos-end: pos
			while [pos-end: find next pos-end {*}] [
				if space <> first back pos-end [
					break
				]
			]

			unless pos-end [
				print "Unmatched asterisk in markdown"
				print result
				quit
			] 

			replace pos {*} {<i>}
			replace pos-end {*} {</i>}
		]
		pos: pos-end
	]

	pos: result
	while [pos: find pos {`}] [
		replace pos {`} {<code>}
		replace pos {`} {</code>}
	]
	
	parse result [
		some [
			[
				s:
				"[" copy label to "]("
				2 skip
				copy url to ")"
				skip
				e:
				(
					change/part s rejoin [{<a href="} url {">} label {</a>}] e
					s: head s
				)
				:s
			] 
		|
			skip
		]
	]

	replace/all result {--} {&mdash;}

	;-- hacky way to support these known escapes
	;-- Find general solution...
	replace/all result {&amp;delta;} {&delta;}	
	replace/all result {&amp;rarr;} {&rarr;}
	replace/all result {&amp;larr;} {&larr;}
	replace/all result {&amp;darr;} {&darr;}
	replace/all result {&amp;uarr;} {&uarr;}
	replace/all result {&amp;eacute;} {&eacute;}
	replace/all result {&amp;iuml;} {&iuml;}
	replace/all result {&amp;asymp;} {&asymp;}
	replace/all result {&amp;nbsp;} {&nbsp;}

	replace/all result {&lt;sup&gt;} {<sup>}
	replace/all result {&lt;/sup&gt;} {</sup>}

	replace/all result {&lt;sub&gt;} {<sub>}
	replace/all result {&lt;/sub&gt;} {</sub>}

	replace/all result {&lt;br&gt;} {<br />}
	replace/all result {&lt;br /&gt;} {<br />}

	return result
]


htmlify-group: function [
	{The ordinary htmlify function considers blocks to be elements,
	but this treats blocks as groups.}

	blk [block!]
] [
	result: copy {}
	pos: blk
	while [not tail? pos] [
		case [
		 	all [
		 		head? pos
		 		tail? pos
		 	] [
		 		append result htmlify/nestfirst/nestlast first pos
		 	]
		 	head? pos [
		 		append result htmlify/nestfirst first pos
		 	]
		 	tail? pos [
		 		append result htmlify/nestlast first pos
		 	]
		 	true [
				append result htmlify first pos
			]
		]
		pos: next pos
	]
	return result
] 


begin-span-or-div: function [
	is-span [none! logic!]
	class [word!]
] [
	rejoin ["<" either is-span ["span"] ["div"] space {class="} to string! class {">}]
]


end-span-or-div: function [
	is-span [none! logic!]
] [
	rejoin ["</" either is-span ["span"] ["div"] {>} lf]
]


htmlify: function [
	{Recursively produces the HTML for a Draem Rebol structure.}
	e
	/nestfirst
	/nestlast
	/span
] [
	;-- For uniformity of processing, wrap in a block
	unless block? e [
		e: append/only copy [] e
	]

	error: catch [
		if 'center = first e [
			;-- centering requires CSS as <center> is invalid now :-/
			;-- worry about it in a bit, don't center it for now
			;-- treat as if it didn't say center
			take e
		]

		switch/default first e [
			picture [
				result: rejoin [
					{<div class="picture">}
					{<a href="http://s159.photobucket.com/albums/t125/realityhandbook/}
					second e
					{">}
					
					{<img src="http://i159.photobucket.com/albums/t125/realityhandbook/}
					{th_}
					second e
					{" />}
					{</a>}
					{</div>}
					lf
				]
			]

			divider [
				;-- horizontal line
				result: rejoin ["<hr />" space]
			]

			separator [
				;-- some space, but no line
				result: rejoin ["<span>&nbsp;<br /></span>"]
			]

			quote [
				result: rejoin [
					{<blockquote>}
					either block? second e [
						htmlify-group second e
					] [
						htmlify second e
					]
					;-- http://html5doctor.com/blockquote-q-cite/
					either third e [
						rejoin [{<footer>} htmlify/span third e {</footer>}]
					] [
						{}
					]
					{</blockquote>}
					lf
				]
			]

			note update [

				either date? second e [
					date: second e
					content: third e
				] [
					date: none
					content: second e
				]

				is-note: 'note = first e

				result: rejoin [
					{<div class="} either is-note [{note}] [{update}] {">}
					either is-note [
						{<span class="note-span">Note</span>}
					] [
						rejoin [{<span class="update-span">UPDATE} either date [rejoin [space date]] [{}] {</span>}]
					]
					space
					either block? content [
						htmlify-group content
					] [
						htmlify/span content
					]
					{</div>}
					lf
				]
			]

			image [
				assert [url? second e]
				assert [pair? third e]
				assert [string? fourth e]
				result: rejoin [
					{<div class="picture">}
					{<a href="} to string! second e {">}
					{<img src="} to string! second e {"} space
					{alt="} fourth e {"} space
					{width="} first third e {"} space
					{height="} second third e {" />}
					{</a>}
					{</div>}
				]
			]

			button [
				assert [url? second e]
				assert [pair? third e]
				assert [string? fourth e]
				assert [url? fifth e]
				result: rejoin [
					{<div class="picture">}
					{<a href="} to string! fifth e {">}
					{<img src="} to string! second e {"} space
					{alt="} fourth e {"} space
					{width="} first third e {"} space
					{height="} second third e {" />}
					{</a>}
					{</div>}
				]

			]

			more [
				result: {} ;-- output nothing for now
				comment [
					result: rejoin [{<p><i>Read more...</i></p>} lf]
				]
			]

			error
			text
			code [
				either word? second e [
					language: second e
					code: third e
				] [
					language: none
					code: second e
				]

				if language = 'text [
					language = none
				]

				;-- Current markup is expected to be HTML compatible
				;-- http://stackoverflow.com/a/13010144/211160
				replace/all code "&" "&amp;" ;-- ampersand has to be first, or you double escape!
				replace/all code "<" "&lt;"
				replace/all code ">" "&gt;"

				;-- Trim empty lines on top or bottom
				;-- (they might make the source easier to read)
				code-lines: split code lf
				if "" = trim copy first code-lines [
					take code-lines
				]
				if "" = trim copy last code-lines [
					take/last code-lines
				]
				foreach line code-lines [
					append line lf
				]

				needs-pre: find [text code] first e
				needs-code: find [code error] first e 

				;-- TODO: work out the right language classes for google code prettify
				;-- http://stackoverflow.com/q/11742907/211160
				result: rejoin [
					either needs-pre [{<pre>}] [{}]
					either needs-code [{<code>}] [{}]
					rejoin code-lines
					either needs-code [{</code>}] [{}]
					either needs-pre [{</pre>}] [{}]
					lf
				]
			]

			heading [
				result: rejoin [{<h3>} second e {</h3>} lf]
			]

			group [
				;-- treat the rest of the elements as a group
				;-- would be ambiguous if we just used a naked block to do this
				result: htmlify-group next e
			]

			list [
				unless all [
					block? second e
				] [
					throw make error! "Bad list found" 
				]
				result: copy {<ul>}
				foreach elem second e [
					append result rejoin [
						{<li>}
						htmlify elem
						{</li>}
						lf
					]
				]
				append result rejoin [{</ul>} lf]
			]

			html [
				unless string? second e [
					throw make error! "Bad raw HTML"
				]
				result: second e
			]

			youtube [
				;-- I like the idea of being able to put actual working youtube URLs in
				;-- without having to extract the stupid ID, so I can just click on the
				;-- video from the source I'm writing.

				;-- But revisit what's tolerated and what isn't
				unless all [
					url? second e
					pair? third e
					parse to string! second e [
						["http" [opt "s"] "://" [opt "www."] "youtube.com/v/" copy video-id to [end | "?"]]
					|
						["http" [opt "s"] "://" [opt "www."] "youtube.com/watch" thru "v=" copy video-id to [end | "#"]]
					|
						["http" [opt "s"] "://" [opt "www."] "youtube.com/embed/" copy video-id to [end | "#"]]
					]
				] [
					throw make error! "Bad youtube embed"
				]
				;-- http://www.webupd8.org/2010/07/embed-youtube-videos-in-html5-new.html
				result: rejoin [
					{<div class="youtube">}
					{<iframe class="youtube-player"} space

					;-- Integer conversion needed as first 10x20 returns 10.0 :-/
					{width="} to integer! first third e {"} space
					{height="} to integer! second third e {"} space
					{src="http://www.youtube.com/embed/} video-id {">}
					{</iframe>}
					{</div>}
				]
			]
		] [
			case [
				url? first e [
					url: to string! first e

					;-- put in better url encoding logic or decide what should be done
					replace/all url "&" "&amp;"

					result: rejoin [
						begin-span-or-div span 'url
						{<a href="} url {">}
						case [
							none? second e [url]
							string? second e [second e]
							true [throw make error! "Bad URL specification"]
						]
						{</a>}
						end-span-or-div span
						lf
					]
				]

				if all [
					1 = length? e
					string? first e
				] [
					;-- If the first element of a block is a string, then all the 
					;-- elements must be strings.  

					result: rejoin [
						begin-span-or-div span 'exposition
						dream-markup first e
						end-span-or-div span
					]
				]

				set-word? first e [
					;; Dialogue

					result: rejoin [
						begin-span-or-div span 'dialogue
						{<span class="character">} stringify first+ e {</span>} ":" space 
						either paren? first e [
							rejoin [{<span class="action">} "(" first+ e ")" {</span>} space]
						] [
							{}
						]

						{"} dream-markup first+ e {"}
						end-span-or-div span
					]
				]
				true [
					throw make error! "Unrecognized Draem block" 
				]
			]
		]

		;-- No error
		none
	]

	if error [
		probe error
		probe e
		quit
	]

	return result
]

write-entry: function [
	entry [object!]

	earlier-entry [none! object!]

	later-entry [none! object!]

	html-file [file!]
] [

	print [{write-entry} html-file]
	
	content-html: htmlify-group entry/content
	
	html: compose [
		(django-extends %entry.html)
		
		(django-block/inline "keywords" [
			comma-separated head insert copy entry/header/tags entry/header/category
		])
		
		(django-block/inline "description" [
			comma-separated reduce [
				{Author: A.E. 1020}
				rejoin [{Category:} space stringify entry/header/category]
				rejoin [{Title:} space entry/header/title]
				rejoin [{date:} space entry/header/date/date]
				rejoin [{Length:} space length? (split content-html space) space "words"]
			]
		])
		
		(django-block/inline "title" [
			rejoin [entry/header/category space ":" space entry/header/title]
		])
		
		(django-block/inline "header" [
			entry/header/title
		])
		
		(django-path [
			rejoin [
				{<li>}
					{<a href="} draem/config/site-url {category/}
					stringify/dashes entry/header/category {/">} 
					stringify entry/header/category 
					{</a>}
				{</li>}
				{<li><span>}
					entry/header/title
				{</span></li>}
			]
		])
		
		(django-block "date" [
			entry/header/date
		])

		(django-block "tags" [
			either empty? entry/header/tags [
				"(none)"
			] [
				comma-separated/callback entry/header/tags function [tag] [
					rejoin [ 
						{<a href="} draem/config/site-url {tag/}
						stringify/dashes tag
						{/">} stringify tag {</a>}
					]
				]
			]
		])

		(django-block "characters" [
			either empty? select draem/indexes/slug-to-characters entry/header/slug [
				"(none)"
			] [
				 comma-separated/callback select draem/indexes/slug-to-characters entry/header/slug function [character] [
					rejoin [ 
						{<a href="} draem/config/site-url {character/}
						stringify/dashes character
						{/">} stringify character {</a>}
					]
				]
			]
		])

		(django-block "content" [
			content-html
		])
		
		(either later-entry [django-block {nexttitle} [
			later-entry/header/title
		]] [])
		
		(either earlier-entry [django-block {prevtitle} [
			earlier-entry/header/title
		]] [])
		
		(either later-entry [django-block {nexturl} [
			url-for-entry later-entry
		]] [])
		
		(either earlier-entry [django-block {prevurl} [
			url-for-entry earlier-entry
		]] [])

		(django-block/inline "footer" [
			draem/config/site-footer
		])
	]
	
	write/lines html-file html
]

make-templates: function [
	{ Generates the django templates from the entries and draem/indexes }

	entries [block!]
	indexes [object!]
	templates-dir [file!]
] [
	draem/stage "TEMPLATES OUTPUT"

	unless exists? templates-dir [
		make-dir templates-dir
	]

	;; WRITE OUT THE INDIVIDUAL ENTRIES, MAKE USE OF SORTING INFORMATION
	;; OMIT ABOUT AND CONTACT CATEGORIES FROM MAIN INDEX AND USE SPECIAL URL
	;; ALSO WRITE OUT A MAIN PAGE IN REVERSE CHRONOLOGICAL ORDER

	draem/stage "MAIN OUTPUT LOOP"

	index-html: compose [
		(django-extends %base.html)
		
		(django-block/inline "title" [
			draem/config/site-title
		])

		(django-block/inline "header" [
			draem/config/site-tagline
		])

		(django-block/inline "path" [
			rejoin [{<li><span>} draem/config/site-url {</span></li>}]
		])		

		"{% block main %}"

		(draem/config/site-intro)
	]

	iter: entries
	while [not tail? iter] [
		entry: first iter
		earlier-entry: first next iter ;-- maybe none
		later-entry: first back iter ;-- maybe none

		either fake-category entry/header/category [
			write-entry entry none none rejoin [templates-dir stringify/dashes entry/header/category %.html]
		] [
			directory: rejoin [
				templates-dir stringify/dashes entry/header/category {/}
			]
			unless exists? directory [
				make-dir directory
			]
			
			write-entry entry earlier-entry later-entry rejoin [directory entry/header/slug %.html]
			append index-html link-to-entry entry
		]

		iter: next iter
	]

	append index-html "{% endblock main %}"

	append index-html compose [
		(django-block/inline "footer" [
			draem/config/site-footer
		])		
	]

	write/lines rejoin [templates-dir %index.html] index-html



	;; GENERATE THE TAG LIST AND A PAGE FOR EACH TAG

	draem/stage "TAG OUTPUT"
	tag-list-html: compose [
		(django-extends %taglist.html)

		(django-block/inline "title" [
			{All Tags}
		])
		
		(django-block/inline "header" [
			rejoin ["All Tags for " draem/config/site-name]
		])

		(django-path [
			{<li><span> Tag List </span></li>}
		])
		
		"{% block tags %}"
	]

	foreach [tag entries] draem/indexes/tag-to-entries [
		directory: to file! rejoin [templates-dir %tags/]
		if (not exists? directory) [
			make-dir directory
		]
		append tag-list-html link-to-tag/count tag length? entries
		
		tag-html: compose [
			(django-extends %tag.html)

			(django-block/inline "title" [
				rejoin [{tag:} space stringify tag]
			])

			(django-block/inline "header" [
				stringify tag
			])
		
			(django-path [
				{<li><a href="} draem/config/site-url {tag/" title="Tag List">Tag</a></li>}
				rejoin [{<li><span>} stringify tag {</span></li>}]
			])
			
			"{% block entries %}"
		]
		
		foreach entry entries [
			unless fake-category entry/header/category [
				append tag-html link-to-entry entry
			]
		]
		
		append tag-html "{% endblock entries %}"
		write/lines rejoin [directory stringify/dashes tag ".html"] tag-html
	]

	append tag-list-html "{% endblock tags %}"
	write/lines rejoin [templates-dir %tags.html] tag-list-html


	;; GENERATE THE CHARACTER LIST AND A PAGE FOR EACH CHARACTER

	draem/stage "CHARACTER OUTPUT"
	character-list-html: compose [
		(django-extends %characterlist.html)

		(django-block/inline "title" [
			{Character List}
		])

		(django-block/inline "header" [
			{Character List}
		])

		(django-path [
			{<li><span> Character List </span></li>}
		])

		"{% block characters %}"
	]

	foreach [character entries] draem/indexes/character-to-entries [
		directory: to file! rejoin [templates-dir %characters/]
		unless exists? directory [
			make-dir directory
		]
		append character-list-html link-to-character/count character length? entries
		
		character-html: compose [
			(django-extends %character.html)

			(django-block/inline "title" [
				rejoin [{character:} space stringify character]
			])
			
			(django-block/inline "header" [
				stringify character
			])
			
			(django-path [
				{<li><a href="} draem/config/site-url {character/" title="Character List">Character</a></li>}
				rejoin [{<li><span>} stringify character {</span></li>}]
			])
			
			"{% block entries %}"
		]
		
		foreach entry entries [
			unless fake-category entry/header/category [
				append character-html link-to-entry entry
			]
		]
		
		append character-html "{% endblock entries %}"
		write/lines rejoin [directory stringify/dashes character ".html"] character-html
	]

	append character-list-html "{% endblock characters %}"
	write/lines rejoin [templates-dir %characters.html] character-list-html



	;; WRITE OUT CATEGORY PAGES

	draem/stage "CATEGORY OUTPUT"
	category-list-html: compose [
		(django-extends %categorylist.html)

		(django-block/inline "title" [
			rejoin ["All Categories for " draem/config/site-name]
		])
		
		(django-block/inline "header" [
			{Category List}
		])

		(django-path [
			{<li><span>Category List</span></li>}
		])
		
		"{% block categories %}"
	]

	foreach [category entries] draem/indexes/category-to-entries [
		if fake-category category [
			continue
		]

		directory: to file! rejoin [templates-dir %categories/]
		unless exists? directory [
			make-dir directory
		]
		append category-list-html link-to-category/count category length? entries
		
		category-html: compose [
			(django-extends %category.html)
			
			(django-block/inline "title" [
				rejoin [{category:} space stringify category]
			])
			
			(django-block/inline "header" [
				stringify category
			])
			
			(django-path [
				{<li><a href="} draem/config/site-url {category/" title="Category">Category</a></li>}
				rejoin [{<li><span>} stringify category {</span></li>}]
			])

			"{% block entries %}"
		]
		
		foreach entry entries [
			append category-html link-to-entry entry
		]
		
		append category-html "{% endblock entries %}"
		write/lines rejoin [directory stringify/dashes category ".html"] category-html
	]

	append category-list-html "{% endblock categories %}"
	write/lines rejoin [templates-dir %categories.html] category-list-html
]
