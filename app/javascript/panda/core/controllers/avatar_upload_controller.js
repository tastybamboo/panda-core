import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="avatar-upload"
export default class extends Controller {
  static targets = ["input", "preview", "placeholder", "fileInfo", "fileName", "fileSize"]

  connect() {
    this.originalPreviewSrc = this.hasPreviewTarget ? this.previewTarget.src : null
    this.hadOriginalAvatar = this.hasPreviewTarget && !this.previewTarget.classList.contains("hidden")
  }

  handleFileSelect() {
    const file = this.inputTarget.files[0]
    if (!file || !file.type.startsWith("image/")) return

    const reader = new FileReader()
    reader.onload = (e) => {
      // Show preview image, hide placeholder
      if (this.hasPreviewTarget) {
        this.previewTarget.src = e.target.result
        this.previewTarget.classList.remove("hidden")
      }
      if (this.hasPlaceholderTarget) {
        this.placeholderTarget.classList.add("hidden")
      }

      // Show file info
      if (this.hasFileInfoTarget) {
        this.fileInfoTarget.classList.remove("hidden")
      }
      if (this.hasFileNameTarget) {
        this.fileNameTarget.textContent = file.name
      }
      if (this.hasFileSizeTarget) {
        this.fileSizeTarget.textContent = this.formatFileSize(file.size)
      }
    }
    reader.readAsDataURL(file)
  }

  remove() {
    // Clear file input using DataTransfer pattern
    const dataTransfer = new DataTransfer()
    this.inputTarget.files = dataTransfer.files

    // Restore original state
    if (this.hadOriginalAvatar && this.hasPreviewTarget) {
      this.previewTarget.src = this.originalPreviewSrc
      this.previewTarget.classList.remove("hidden")
      if (this.hasPlaceholderTarget) {
        this.placeholderTarget.classList.add("hidden")
      }
    } else {
      // No original avatar — show placeholder
      if (this.hasPreviewTarget) {
        this.previewTarget.classList.add("hidden")
      }
      if (this.hasPlaceholderTarget) {
        this.placeholderTarget.classList.remove("hidden")
      }
    }

    // Hide file info
    if (this.hasFileInfoTarget) {
      this.fileInfoTarget.classList.add("hidden")
    }
  }

  formatFileSize(bytes) {
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }
}
