LANGUAGE = (navigator.languages?[0] or navigator.language or "en").match(/^\w+/ig)?[0] or "en"
console.log "Language: " + LANGUAGE.toUpperCase()

languages =
	ru:
		name: "viz"
	en:
		name: "viz"

findLanguage = (name) ->
	for language in config.languages
		if language.language == name
			return language

	return undefined

for name, language of languages
	ext = findLanguage name
	continue unless ext

	Object.assign language, ext

language = languages[LANGUAGE] or languages["en"]

colors = ["red", "green", "blue", "yellow", "pink", "gray", "brown"]
language.colors = (i) ->
	return colors[i] or 
		colors[Math.abs(i) / colors.length] or 
		colors[Math.abs(i) % colors.length - 1]

console.log "Using language", language

module.exports = {
	languages
	language
}
