Rebol [
	Title: "Make Realityhandbook Website"
	Description: {

	Builds the Realityhandbook website from a directory of journal entries.

	}

	Home: http://realityhandbook.org/
	License: 'mit

	Date: 20-Oct-2010
	Version: 3.0.4

	; Header conventions: http://www.rebol.org/one-click-submission-help.r
	File: %make-site.reb
	Type: 'dialect
	Level: 'intermediate

	Usage: {

	Current usage is just to run this script in the directory containing the
	subdirectory %entries/ and it will spit out a directory called %templates/

	}
]

do %common.reb

load-entries: function [
	{Load all the entries and populate the maps.  Returns a block, with the first
	element the list of entries and the second an object containing various
	indexes over the information.}

	entries-dir
	/with entries [block!] indexes [object!]
] [
	unless with [
		; entries list sorted newest first, oldest last
		entries: copy []

		indexes: object [
			; map from tags to list of entries with that tag
			tag-to-entries: make map! []

			; map from character to list of entries where they appear
			character-to-entries: make map! []

			; map from categories to list of entries in that category
			category-to-entries: make map! []

			; map from entry slug to the characters list appearing in it
			slug-to-characters: make map! []

			; map from entry slug to the entry itself
			slug-to-entry: make map! []
		]
	]

	foreach file load entries-dir [
		either dir? file [
			subdir: rejoin [entries-dir file]
			print [{Recursing into:} subdir]
			load-entries/with subdir entries indexes
		] [
			print [{Pre-processing:} file]

			data: load rejoin [entries-dir file]

			pos: data

			unless all [
				'Draem == first+ pos
				block? first pos
			] [
				throw make error! "Entry must start with Draem header"
			]

			header: make object! first+ pos

			unless all [
				in header 'date
				date? header/date
			] [
				throw make error! "Header requires valid date field"
			]

			unless all [
				in header 'slug
				file? header/slug
			] [
				throw make error! "Header requires a file! slug field"
			]

			unless all [
				in header 'title
				string? header/title
			] [
				throw make error! "Header requires a string! title field"
			]

			unless all [
				in header 'tags
				block? header/tags
				does [foreach tag header/tags [unless word? tag return false] true] 
			] [
				throw make error! "Header requires a tags block containing words"
			]

			if find [lucid-dream non-lucid-dream] header/category [ 
				unless any [
					find header/tags 'neutral
					find header/tags 'positive
					find header/tags 'negative
				] [
					probe header/tags
					throw make error! "Dreams must be tagged neutral, positive, or negative"
				]
			]

			unless all [
				in header 'category
				word? header/category
				find [
					about
					essay
					lucid-dream
					non-lucid-dream
					open-letter
					misc
					hypnosis
					guest-dream
					post
					page
				] header/category
			] [
				throw make error! "Header requires a legal category"
			]

			entry: make object! compose/only [
				header: (header)
				content: (copy pos)
			]

			append entries entry
			repend indexes/slug-to-entry [entry/header/slug entry]
		]
	]

	unless with [
		sort/compare entries func [a b] [a/header/date > b/header/date]

		foreach entry entries [
			header: entry/header
			content: entry/content

			either select indexes/category-to-entries header/category [
				append select indexes/category-to-entries header/category entry
			] [
				append indexes/category-to-entries compose/deep copy/deep [(header/category) [(entry)]]
			]

			foreach tag header/tags [
				either select indexes/tag-to-entries tag [
					append select indexes/tag-to-entries tag entry
				] [

					append indexes/tag-to-entries compose/deep copy/deep [(tag) [(entry)]]
				]
			]

			; collect the characters from blocks beginning with set-word in the body
			characters: copy []
			repend indexes/slug-to-characters [entry/header/slug characters]

			pos: content
			while [not tail? pos] [
				line: first+ pos

				if not block? line [
					throw make error! "Each line currently must be a block :-/"
				]

				if all [
					set-word? first line
					not find characters to word! first line
				] [
					append characters to word! first line
				]

				comment [
					if 'picture = first line [
						;;
						;; What to do?  Index or list these?  Scrape them?
						;;
					]
				]
			]

			foreach character characters [
				either select indexes/character-to-entries character [
					append select indexes/character-to-entries character entry
				] [
					append indexes/character-to-entries compose/deep copy/deep [(character) [(entry)]]
				]
			]
		]
	]

	return reduce [entries indexes]
]

context [
	err: catch [

		print "=== LOADING ENTRIES ==="

		set [entries indexes] load-entries %entries/

		probe entries

		print "=== TEMPLATES OUTPUT ==="

		do %make-templates.reb
		make-templates entries indexes %templates/

		print "=== TIMELINE OUTPUT ==="

		do %make-timeline.reb
		make-timeline entries %templates/timeline.xml

		print "=== ATOM FEED OUTPUT ==="

		do %make-atom-feed.reb
		make-atom-feed entries %templates/atom.xml 20

		none
	]

	if err [
		print form err
	]
]

#[unset!]