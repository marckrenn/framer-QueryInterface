

class exports.QueryInterface extends Framer.BaseClass

	_allQueryInterfaces = [] unless _allQueryInterfaces?

	# based on http://stackoverflow.com/a/5158301 by James
	getParameterByName = (name) ->
		if Utils.isInsideFramerCloud()
			location = window.parent.location.search
		else
			location = window.location.search
		match = RegExp("[?&]#{name}=([^&]*)").exec(location)
		match and decodeURIComponent(match[1].replace(/\+/g, " "))


	# based on http://stackoverflow.com/a/11654596 by ellemayo
	updateQueryString = (key, value, url) ->
		
		unless url?

			if Utils.isInsideFramerCloud()
				url = window.parent.location.href
			else
				url = window.location.href

		key = key.replace("#", "%23")
		value = value.replace("#", "%23") if typeof value is "string"
		re = new RegExp("([?&])#{key}=.*?(&|#|$)(.*)", "gi")
		hash = undefined

		if re.test(url)

			if typeof value isnt "undefined" and value isnt null
				url.replace(re, "$1#{key}=#{value}$2$3")

			else
				hash = url.split("#")
				url = hash[0].replace(re, "$1$3").replace(/(&|\?)$/, "")
				url += "##{hash[1]}" if typeof hash[1] isnt "undefined" and hash[1] isnt null
				return url

		else

			if typeof value isnt "undefined" and value isnt null
				separator = if url.indexOf("?") isnt -1 then "&" else "?"
				hash = url.split("#")
				url = "#{hash[0]}#{separator}#{key}=#{value}"
				url += "##{hash[1]}" if typeof hash[1] isnt "undefined" and hash[1] isnt null
				return url

			else url


	@define "value",

		get: ->

			if getParameterByName(@key) and @fetchQuery
				@value = @_parse(getParameterByName(@key), false)

			else if @saveLocal is false or @loadLocal is false

				if @_val is undefined or @_val is "undefined"
					@default
				else @_val

			else if localStorage.getItem("#{window.location.pathname}?#{@key}=") and @loadLocal

				localValue = localStorage.getItem("#{window.location.pathname}?#{@key}=")

				if localValue is undefined or localValue is "undefined"
					@reset()
				else
					val = @_parse(localValue, false)

			else @value = @default


		set: (val) ->

			return if @default is undefined or @key is undefined

			@_val = val = @_parse(val, true)

			if @saveLocal
				localStorage.setItem("#{window.location.pathname}?#{@key}=", val)

			if @publish is true
				newUrl = updateQueryString(@key, val)

				if Utils.isFramerStudio() isnt true or @_forcePublish
					window.history.replaceState({path: newUrl}, "#{@key} changed to #{val}", newUrl)

				if Utils.isInsideIframe()
					window.parent.history.replaceState({path: newUrl}, "#{@key} changed to #{val}", newUrl)

			else
				newUrl = updateQueryString(@key)

				if Utils.isInsideIframe()
					print newUrl
					window.parent.history.replaceState({path: newUrl}, "#{@key} removed from URI", newUrl)
				else if Utils.isInsideIframe() is false
					window.history.replaceState({path: newUrl}, "#{@key} removed from URI", newUrl)


	@define "type", get: -> typeof(@default)


	@define "default",
		get: -> @_default
		set: (val) ->

			return if typeof val is "function" or @key is undefined

			@_default = val

			if localStorage.getItem("#{window.location.pathname}?#{@key}Default=")
				savedDefault = localStorage.getItem("#{window.location.pathname}?#{@key}Default=")

			parsedVal = val.toString()
			localStorage.setItem("#{window.location.pathname}?#{@key}Default=", parsedVal)

			@reset() if parsedVal isnt savedDefault

			if localStorage.getItem("#{window.location.pathname}?#{@key}Type=")
				savedType = localStorage.getItem("#{window.location.pathname}?#{@key}Type=")

			newType = typeof val
			localStorage.setItem("#{window.location.pathname}?#{@key}Type=", newType)

			@reset() if savedType and newType isnt savedType


	constructor: (@options = {}) ->
		@key        = @options.key        ?= undefined
		@publish    = @options.publish    ?= true
		@fetchQuery = @options.fetchQuery ?= true
		@saveLocal  = @options.saveLocal  ?= true
		@loadLocal  = @options.loadLocal  ?= true
		@_forcePublish = false
		super

		_allQueryInterfaces.push(this)

		@value = @value


	_parse: (val, set) ->

		if val is "/reset/" or val is "/default/"
			val = @default

		else

			switch typeof @default
				when "number"
					if val is false or val is null or isNaN(val)
						val = 0
					else if val
						val = Number(val)
						val = @default if isNaN(val)
					else val = @default

				when "boolean"
					switch typeof val
						when "object" then val = Boolean(val)
						when "undefined" then val = false
						when "string"
							if val.toLowerCase() is "true"
								val = true
							else if val.toLowerCase() is "false"
								val = false
							else val = true
						when "number"
							if val is 0 then val = false else val = true

				when "string"
					if val then val = val.toString() else val = @default

				when "object"

					if set

						unless val is undefined or val is null
							val = JSON.stringify(val)
						else val = @default

					else

						unless val is undefined or val is null or val is "undefined" or val is "null"
							val = JSON.parse(val)
						else val = @default

		return val


	reset: -> @value = @default


	@resetAll = ->
		queryInterface.reset() for queryInterface in _allQueryInterfaces

		newUrl = window.location.href.split('?')[0]
		window.history.replaceState({path: newUrl},"Reset all QueryInterfaces", newUrl) if newUrl?
		location.reload()


	@query = ->

		for queryInterface in _allQueryInterfaces
			queryInterface._forcePublish = true
			queryInterface.value = queryInterface.value

		if Utils.isFramerStudio()
			query = "?#{updateQueryString("reloader").split('?')[1]}".replace(/%22/g, "\"")
		else
			query =(window.location.search).replace(/%22/g, "\"")

		for queryInterface in _allQueryInterfaces
			queryInterface._forcePublish = false
			queryInterface.value = queryInterface.value

		return query


