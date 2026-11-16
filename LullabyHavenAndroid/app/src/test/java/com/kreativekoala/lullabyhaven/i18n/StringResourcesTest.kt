package com.kreativekoala.lullabyhaven.i18n

import org.junit.Assert.assertEquals
import org.junit.Test
import org.w3c.dom.Element
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory

/** Every shipped translation must have the same keys and format placeholders as values/. */
class StringResourcesTest {
    private val resDir = listOf(File("src/main/res"), File("app/src/main/res")).first { it.isDirectory }

    private fun load(dir: File): Map<String, String> {
        val doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(File(dir, "strings.xml"))
        val out = linkedMapOf<String, String>()
        val nodes = doc.documentElement.getElementsByTagName("string")
        for (i in 0 until nodes.length) {
            val n = nodes.item(i) as Element
            if (n.getAttribute("translatable") != "false") out[n.getAttribute("name")] = n.textContent
        }
        return out
    }

    private val default = load(File(resDir, "values"))
    private val localeDirs = resDir.listFiles { f -> f.isDirectory && f.name.startsWith("values-") && File(f, "strings.xml").exists() }!!
        .sortedBy { it.name }
    private val spec = Regex("%(\\d+\\$)?[-#+ 0,(]*\\d*(\\.\\d+)?([a-zA-Z])")

    private fun specs(text: String): List<String> {
        var next = 1
        return spec.findAll(text.replace("%%", "")).map { m ->
            val pos = m.groupValues[1].removeSuffix("$").ifEmpty { (next++).toString() }
            "$pos:${m.groupValues[3]}"
        }.sorted().toList()
    }

    @Test
    fun everyLocaleHasTheSameKeys() {
        for (dir in localeDirs) {
            val r = load(dir)
            assertEquals("${dir.name}: missing", emptySet<String>(), default.keys - r.keys - "app_name") // the brand name is not translated
            assertEquals("${dir.name}: extra", emptySet<String>(), r.keys - default.keys)
        }
    }

    @Test
    fun placeholdersMatchTheDefault() {
        for (dir in localeDirs) for ((k, v) in load(dir)) assertEquals("${dir.name}:$k", specs(default[k] ?: continue), specs(v))
    }

    @Test
    fun localeConfigListsTheShippedLanguages() {
        val doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(File(resDir, "xml/locales_config.xml"))
        val l = doc.getElementsByTagName("locale")
        val listed = (0 until l.length).map { (l.item(it) as Element).getAttribute("android:name").substringBefore("-").lowercase() }.toSet()
        val shipped = localeDirs.map { it.name.removePrefix("values-").substringBefore("-r") }
            .map { if (it == "in") "id" else it }.toSet() + "en"
        assertEquals(shipped, listed)
    }
}
