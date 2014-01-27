Rebol [
	Title: {Hacky Rebol Markdown}
	Description {
		At the time of writing, there is no official Rebol markdown 
		library.  People have "rolled their own" markdown-like things, but
		nothing takes a markdown string and produces HTML (or a DOM that
		might be used to make HTML).

		I made a quick and dirty implementation just to try and get
		through a certain conversion, assuming that there must be a plan
		to make a "real" Markdown that could handle the weird cases like
		on StackOverflow, which does a fair amount of "magic" to be able
		to take care of HTML entities like &rarr; and yet still transform
		"AT&T" => "AT&amp;T".

		My hope is that someone else is going to write the Markdown
		translator and I won't have to.  And in that spirit, I'm pulling
		out the Markdown from Draem into its own file.  It's bad, don't
		look at it (unless it inspires you to write the good one).
	}
]

;-- Bridge the as-yet-unmerged to mainline naming change :-/
changed-function: if 10 = length? spec-of :function [
	old-function: :function
	function: :funct
	unset 'funct
	true
]


markdown: context [
	to-html: function [str [string!]] [
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
			unless find pos {**} [
				print "Unmatched double asterisk in markdown"
				quit
			]
			replace pos {**} {</b>}
		]

		star-substitution: to char! 2744 ;-- a snowflake...?

		pos: result
		while [pos: find pos {`}] [
			either pos-end: find next pos {`} [
				;-- do a substitution trick on the asterisks
				;-- inside the code, so they don't get processed
				;-- we'll put them back later
				while [pos-replace: find pos {*}] [
					unless all [
						pos-replace
						(index? pos-replace) < (index? pos-end)
					] [
						break
					]
					change pos-replace star-substitution
				]
				replace pos {`} {<code>}
				replace pos {`} {</code>}
			] [
				print "Unmatched backquote in markdown"
				print result
				quit
			]
		]

		pos: result
		while [pos: find pos {*}] [
			if any [
				;-- Ignore "* " as italic start
				space = second pos
				all [
					;-- Ignore " * " as italic start
					space = first back pos
					space = second pos
				]
			] [
				++ pos
				continue
			]

			if tail? pos [
				break
			]

			pos-end: pos
			while [pos-end: find next pos-end {*}] [
				if space = first back pos-end [
					;-- Ignore " *" as italic end
					continue
				]
				break
			]

			unless pos-end [
				print "Unmatched asterisk in markdown"
				print result
				quit
			] 

			replace pos {*} {<i>}
			replace pos-end {*} {</i>}

			pos: pos-end
		]
		
		replace/all result star-substitution {*}

		parse result [
			some [
				[
					s:
					"[" copy label to "]("
					2 skip
					copy url to ")"
					skip
					e:
					;-- http://example.com/foo_(bar), for instance, common on wiki
					;-- ...but then how about ([text](http://example.com))
					;-- heuristics need to be applied in such cases, but I need
					;-- wiki links, so until the heuristics arrive I'll make sure
					;-- links aren't put in parentheses like that w/searches on )) 
					(
						if #")" = first e [
							e: next e
							append url #")"
						]
						assert [any [
							url = find url "http://"
							url = find url "https://"
							url = find url "ftp://"
						]]
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
		recover-entity: func [entity [word!]] [
			replace/all result rejoin [
				{&amp;} to string! entity {;}
			] rejoin [
				{&} to string! entity {;}
			]
		]
		foreach entity [
			delta
			larr rarr uarr darr
			eacute aacute iuml asymp nbsp
			iquest mu
		] [
			recover-entity entity
		]

		;-- Hacky way to get a few HTML things back
		;-- Need to study Markdown to know what the rules are
		replace/all result {&lt;sup&gt;} {<sup>}
		replace/all result {&lt;/sup&gt;} {</sup>}

		replace/all result {&lt;sub&gt;} {<sub>}
		replace/all result {&lt;/sub&gt;} {</sub>}

		replace/all result {&lt;br&gt;} {<br />}
		replace/all result {&lt;br /&gt;} {<br />}

		return result
	]
]


;-- Restore funct/function expectation of caller
if changed-function [
	funct: :function
	function: :old-function
]