package com.kreativekoala.lullabyhaven

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.kreativekoala.lullabyhaven.ui.navigation.LullabyHavenNavGraph
import com.kreativekoala.lullabyhaven.ui.theme.LullabyHavenTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            LullabyHavenTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    LullabyHavenNavGraph()
                }
            }
        }
    }
}
