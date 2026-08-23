package com.kreativekoala.lullabyhaven.ui.myvoice

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kreativekoala.lullabyhaven.data.repository.VoiceRepository
import com.kreativekoala.lullabyhaven.domain.model.SavedVoice
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class MyVoiceUiState(
    val isLoading: Boolean = false,
    val voices: List<SavedVoice> = emptyList(),
    val error: String? = null
)

@HiltViewModel
class MyVoiceViewModel @Inject constructor(
    private val voiceRepository: VoiceRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(MyVoiceUiState())
    val uiState: StateFlow<MyVoiceUiState> = _uiState.asStateFlow()

    fun loadVoices() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            voiceRepository.listVoices()
                .onSuccess { voices ->
                    _uiState.value = _uiState.value.copy(isLoading = false, voices = voices)
                }
                .onFailure { e ->
                    // Backend call is real but not yet exercised against production; surface the
                    // error rather than fail silently so this is obviously not "done" until wired.
                    _uiState.value = _uiState.value.copy(isLoading = false, error = e.message ?: "Couldn't load voices")
                }
        }
    }

    fun deleteVoice(id: String) {
        viewModelScope.launch {
            voiceRepository.deleteVoice(id).onSuccess { loadVoices() }
        }
    }
}
