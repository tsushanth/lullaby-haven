package com.kreativekoala.lullabyhaven.domain.model

/**
 * Mirrors LullabyHaven (iOS) Models/BedtimeStory.swift.
 * All stories are originals, narrated on-device either by a standard preset voice
 * or by a parent's own cloned voice via the shared voice-generation backend.
 */
data class BedtimeStory(
    val id: String,
    val title: String,
    val summary: String,
    val body: String,
    val minAge: Int,
    val maxAge: Int,
    val estimatedMinutes: Int
) {
    val ageRangeDescription: String
        get() = "Ages $minAge–$maxAge"

    companion object {
        /**
         * Same 6 originals as iOS BedtimeStory.allStories. Kept local (no backend call)
         * until story generation is wired up on Android -- see StoryRepository TODOs.
         */
        val allStories: List<BedtimeStory> = listOf(
            BedtimeStory(
                id = "story_sunflower_moon",
                title = "The Sunflower Who Wanted to Touch the Moon",
                summary = "A short, gentle story about patience.",
                body = "Once upon a time, there was a small sunflower named Pip who lived in a quiet garden. " +
                    "Every night, Pip looked up at the moon and whispered, \"I want to touch you.\" " +
                    "The moon smiled and said, \"Grow slowly, little one. You don't need to rush.\" " +
                    "So Pip grew, day by day, leaf by leaf, until Pip's petals brushed the morning sky. " +
                    "And though Pip never reached the moon, Pip learned that growing tall, like growing up, " +
                    "happens one calm day at a time. Goodnight, little sunflower. Goodnight, little dreamer.",
                minAge = 3, maxAge = 7, estimatedMinutes = 4
            ),
            BedtimeStory(
                id = "story_mira_rocket",
                title = "Mira and the Tiny Rocket",
                summary = "Mira fixes a broken paper rocket with kindness.",
                body = "Mira found a paper rocket on her windowsill, but one of its wings was torn. " +
                    "\"Don't worry,\" Mira said softly. \"I'll help you fly again.\" " +
                    "She taped the wing, painted a star on the side, and whispered a wish. " +
                    "The rocket lifted gently into the sky, weaving past the clouds, past the stars, " +
                    "past the moon, and back to Mira's window — just in time for bedtime. " +
                    "\"Goodnight, little rocket,\" Mira said, tucking it under her pillow. " +
                    "\"Tomorrow, we'll fly again.\"",
                minAge = 3, maxAge = 8, estimatedMinutes = 5
            ),
            BedtimeStory(
                id = "story_quiet_dragon",
                title = "The Quiet Dragon",
                summary = "Even loud feelings get sleepy eventually.",
                body = "There was once a dragon who lived inside a cave that nobody knew about. " +
                    "When the dragon was happy, it sang. When the dragon was sad, it stomped. " +
                    "When the dragon was angry, it breathed warm, golden fire that lit up the whole cave. " +
                    "One night, the dragon noticed something new — a feeling that felt like a soft blanket. " +
                    "\"I think this is sleepy,\" the dragon whispered. " +
                    "It curled up, tucked its tail around its nose, and closed its big golden eyes. " +
                    "And the cave was quiet. And the dragon was warm. " +
                    "And tomorrow, the dragon would sing again.",
                minAge = 4, maxAge = 8, estimatedMinutes = 6
            ),
            BedtimeStory(
                id = "story_owl_lighthouse",
                title = "The Owl Who Lived in a Lighthouse",
                summary = "A lighthouse owl learns that quiet is its own kind of light.",
                body = "High on a cliff by the dark blue sea, an owl named Hooper lived inside a tall lighthouse. " +
                    "Every night, the lighthouse swept its bright beam across the waves to keep the boats safe. " +
                    "But Hooper preferred the quiet corner at the top, where the moonlight pooled like milk. " +
                    "One stormy night, the lighthouse light went out. " +
                    "Hooper spread his soft, silver wings and circled the lighthouse, hooting gently. " +
                    "The fishermen below heard him and steered toward the sound. " +
                    "They came home safe. And Hooper learned that even quiet voices can be guiding lights. " +
                    "Goodnight, little keeper. Goodnight, soft moon.",
                minAge = 4, maxAge = 8, estimatedMinutes = 6
            ),
            BedtimeStory(
                id = "story_blanket_factory",
                title = "The Blanket Factory at the End of the Day",
                summary = "Where do warm feelings come from at bedtime?",
                body = "Far above the clouds, there is a factory where blankets are made. " +
                    "Not from yarn — from yawns. " +
                    "Every yawn in the world floats up, up, up, and lands on a big silver loom, " +
                    "where a team of tiny weavers stitches it into a piece of cozy. " +
                    "When you yawn tonight, listen carefully — you might hear the looms clicking, far away. " +
                    "And when you close your eyes, one of those blankets is on its way to you. " +
                    "Goodnight, little weaver. Goodnight, little yawn.",
                minAge = 3, maxAge = 6, estimatedMinutes = 4
            ),
            BedtimeStory(
                id = "story_sleepy_train",
                title = "The Sleepy Train",
                summary = "All aboard the slowest, softest train in the world.",
                body = "The Sleepy Train doesn't go to a town or a station. " +
                    "It rolls along a single track that loops gently around a soft, dark field. " +
                    "Its wheels go: clack-clack… clack-clack… clack-clack… " +
                    "slower than a heartbeat, softer than rain. " +
                    "All the passengers wear pajamas. " +
                    "Some are holding stuffed animals. Some are already asleep. " +
                    "The conductor wears slippers and never speaks above a whisper. " +
                    "If you listen closely tonight, you might hear the Sleepy Train passing nearby. " +
                    "Climb aboard. Find a window seat. " +
                    "Watch the dark field, and let the wheels carry you. " +
                    "Clack-clack. Clack-clack. Goodnight.",
                minAge = 3, maxAge = 7, estimatedMinutes = 5
            )
        )
    }
}
