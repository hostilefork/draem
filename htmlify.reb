Rebol [
	Title: {Takes input in the Draem dialect and produces HTML}
	File: %htmlify.reb
]


begin-span-or-div: function [
	is-span [none! logic!]
	class [word!]
] [
	combine [{<} (either is-span {span} {div}) space {class="} to string! class {">}]
]


end-span-or-div: function [
	is-span [none! logic!]
] [
	combine [{</} (either is-span {span} {div}) {>}]
]


htmlify: function [
	{Recursively produces the HTML for a Draem Rebol structure.
	Input must be a block of items to turn into HTML, not just
	a block representing an element, so it is legal to pass in
	[[quote "Some text"]] but not merely [quote "Some text"].}
	blk [block!]
	/nestfirst
	/nestlast
	/span
] [
	result: copy {}

	group-rule: [some [
		;-- STRING
		;-- Strings bottom out as being handled by markdown.  If a string
		;-- starts a block, it's expected that the block is going to be
		;-- a group of elements; hence there are no parameters.
		set str string! (
			append result combine [
				(begin-span-or-div span 'exposition) newline
				markdown/to-html str
				(end-span-or-div span) newline
			]
		)
	|
		;-- DIVIDER
		;-- Puts in a horizontal line element.
		['divider | and block! into ['divider end]] (
			append result combine [<hr> newline]
		)
	|
		;-- SEPARATOR
		;-- Adds some spacing, but no line.
		['separator | and block! into ['separator end]] (
			append result combine [<span> {&nbsp;} <br /> </span> newline]
		)
	|
		;-- MORE
		;-- WordPress has a feature for showing where the "cut" should
		;-- be, with a "read more..." link when summarizing articles.
		;-- I preserved this information but do not use it yet.
		['more | and block! into ['more end]] (
			append result combine [<!-- more --> newline]
		)
	|
		;-- URL
		;-- Can be either lone URL, or block with URL and anchor label.
		;-- If lone URL, the URL is used as the anchor text also.
		[
			[set url url!] (
				anchor-text: url
			)
		|
			into [
				[set url url!]
				[set anchor-text string!]
				end
			]
		] (
			;-- put in better url encoding logic or decide what should be done
			replace/all url "&" "&amp;"

			append result combine [
				(begin-span-or-div span 'url) newline
				{<a href="} url {">}
				anchor-text
				</a>
				(end-span-or-div span) newline
				newline
			]
		)
	|
		and block! into [
			;-- PICTURE
			;-- Hack for dream journal, need to revisit a generalized
			;-- site-wide way of locating media.  See also IMAGE.
			[
				'picture
				set picture-file file!
				end
			] (
			
				append result combine [
					<div class="picture">
					{<a href="http://s159.photobucket.com/albums/t125/realityhandbook/}
					to string! picture-file
					{">}
					
					{<img src="http://i159.photobucket.com/albums/t125/realityhandbook/}
					{th_}
					to string! picture-file
					{">}
					</a>
					</div>
					newline
				]
			)
		|
			;-- IMAGE
			;-- See also PICTURE (hack)
			[
				'image
				[set url url!]
				[set size pair!]
				[set caption string!]
				end
			] (
				append result combine [
					<div class="picture">
					{<a href="} url {">}
						{<img src="} url {"} space
						{alt="} caption {"} space
						{width="} to integer! size/1 {"} space
						{height="} to integer! size/2 {" />}
					</a>
					</div>
				]
			)
		|
			;-- BUTTON
			[
				'button 
				[set image-url url!]
				[set size pair!]
				[set caption string!]
				[set link-url url!]
				end
			] (
				append result combine [
					<div class="picture">
					{<a href="} to string! link-url {">}
						{<img src="} to string! image-url {"} space
						{alt="} caption {"} space
						{width="} to integer! size/1 {"} space
						{height="} to integer! size/2 {" />}
					</a>
					</div>
				]
			)
		|
			;-- QUOTE
			['quote copy args to end] (
				attribution: none

				either end: find args /source [
					assert [2 = length? end]
					attribution: second end
				] [
					end: tail args
				]

				append result combine [
					<blockquote>

					htmlify-range args end

					;-- http://html5doctor.com/blockquote-q-cite/
					if attribution [
						attribution-blk: append/only copy [] attribution
						protect attribution
						[<footer> htmlify/span attribution-blk </footer>]
					]
					</blockquote>
					newline
				]
			)
		|
			;-- NOTE and UPDATE
			[
				['note (is-note: true) | 'update (is-note: false)]
				(date: none) opt [set date date!]
				copy args to end
			] (
				append result combine [
					{<div class="} (either is-note {note} {update}) {">}
					either is-note [
						[<span class="note-span"> {Note} </span>]
					] [
						[
							<span class="update-span"> {UPDATE}
							if date [
								[space date]
							]
							</span>
						]
					]
					space
					either 1 = length? args [
						htmlify/span args
					] [
						htmlify-group args
					]
					</div>
					newline
				]
			)
		|
			;-- CODE, TEXT, ERROR
			[
				and ['code | 'text | 'error] [set verb word!]
				(language: none) opt [set language word!]
				[set code string!]
				end
			] (
				if language = 'text [
					language: none
				]

				;-- Current markup is expected to be HTML compatible
				;-- http://stackoverflow.com/a/13010144/211160
				replace/all code "&" "&amp;" ;-- ampersand has to be first, or you double escape!
				replace/all code "<" "&lt;"
				replace/all code ">" "&gt;"

				trim-head-tail-lines code

				needs-pre-tag: find [text code] verb
				needs-code-tag: find [code error] verb 

				;-- TODO: work out the right language classes for google code prettify
				;-- http://stackoverflow.com/q/11742907/211160
				append result combine [
					if needs-pre-tag [
						[
							{<pre}
							if verb = 'code [
								[
									space
									{class="prettyprint}
									if language [
										[space {lang-} to string! language]
									]
									{"}
								]
							]
							{>}
						]
					]
					(if needs-code-tag <code>)
					code
					(if needs-code-tag </code>)
					(if needs-pre-tag </pre>)
					newline
				]
			)
		|
			;-- HEADING
			[
				'heading
				[set heading-text string!]
				(anchor: none) opt [set anchor file!] 
				end
			] (
				append result combine [
					if anchor [
						[{<a href="#} to string! anchor {">} </a>]
					]
					<h3> markdown/to-html heading-text </h3>
					newline
				]
			)
		|
			;-- LIST
			[
				'list
				copy args to end
			] (
				append result <ul>
				foreach elem args [
					elem-blk: append/only copy [] elem
					protect elem-blk
					append result combine [
						<li>
						htmlify elem-blk
						</li>
						newline
					]
				]
				append result combine [</ul> newline]
			)
		|
			;-- HTML
			[
				'html
				set html string!
				end
			] (
				;-- The HTML construct should probably be more versatile, but
				;-- for the moment let's just limit it to one HTML string
				append result html
			)
		|
			;-- YOUTUBE
			[
				'youtube
				[set url url!]
				[set size pair!]
				end
			] (
				;-- I like the idea of being able to put actual working youtube URLs in
				;-- without having to extract the stupid ID, so I can just click on the
				;-- video from the source I'm writing.

				;-- But revisit what's tolerated and what isn't
				unless all [
					parse to string! url [
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
				append result combine [
					<div class="youtube">
					{<iframe class="youtube-player"} space

					;-- Integer conversion needed as first 10x20 returns 10.0 :-/
					{width="} to integer! size/1 {"} space
					{height="} to integer! size/2 {"} space
					{src="http://www.youtube.com/embed/} video-id {"} space
					;-- http://www.gtpdesigns.com/design-blog/view/w3c-valid-xthml-and-html5-youtube-iframe-embeds
					{allowFullScreen}
					{>}
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
		and block! into [
			[set character set-word!]
			(parenthetical: none)
			opt [set parenthetical tag!]
			[set dialogue-text string!]
			end
		] (
			append result combine [
				begin-span-or-div span 'dialogue
				<span class="character"> stringify character </span> ":" space
				if parenthetical [
					[
						<span class="action">
						"(" to string! parenthetical ")"
						</span> space
					]
				]

				{"} markdown/to-html dialogue-text {"}
				end-span-or-div span
			]
		)
	|
		;-- Should we meet a block that does not match the above,
		;-- try to recurse with the group-rule
		and block! into group-rule
	]]

	unless parse blk group-rule [
		print "INVALID DRAEM DATA - PARSE RETURNED FALSE"
		probe blk
		quit
	]

	assert [string? result]
	assert [not empty? result]
	return result
]


htmlify-range: function [
	{The ordinary htmlify function considers blocks to be elements,
	but this treats blocks as groups.}

	start [block!]
	end [block!]
] [
	assert [(head start) = (head end)]
	assert [1 <= offset? start end]

	result: copy {}
	pos: start
	while [pos <> end] [
		;-- htmlify always expects a block of elements
		blk: append/only copy [] first pos 
		protect blk

		case [
		 	all [
		 		end = next pos
		 		start = pos
		 	] [
		 		append result htmlify/nestfirst/nestlast blk
		 	]
		 	start = pos [
		 		append result htmlify/nestfirst blk
		 	]
		 	end = next pos [
		 		append result htmlify/nestlast blk
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
] [
	assert [blk = head blk]
	htmlify-range blk (tail blk)
]