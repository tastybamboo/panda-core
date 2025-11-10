import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

// Connects to data-controller="image-cropper"
export default class extends Controller {
  static targets = ["input", "preview", "cropperContainer", "croppedInput"]
  static values = {
    aspectRatio: Number,
    minWidth: { type: Number, default: 0 },
    minHeight: { type: Number, default: 0 }
  }

  connect() {
    this.cropper = null
    this.originalFile = null
  }

  disconnect() {
    if (this.cropper) {
      this.cropper.destroy()
      this.cropper = null
    }
  }

  handleFileSelect(event) {
    const file = event.target.files[0]
    if (file && file.type.startsWith('image/')) {
      this.originalFile = file
      this.showCropper(file)
    }
  }

  showCropper(file) {
    const reader = new FileReader()
    reader.onload = (e) => {
      // Show the cropper container
      this.cropperContainerTarget.classList.remove('hidden')

      // Set the image source
      this.previewTarget.src = e.target.result

      // Initialize cropper after a short delay to ensure image is loaded
      setTimeout(() => this.initializeCropper(), 100)
    }
    reader.readAsDataURL(file)
  }

  initializeCropper() {
    // Destroy existing cropper if any
    if (this.cropper) {
      this.cropper.destroy()
    }

    const options = {
      viewMode: 1,
      dragMode: 'move',
      aspectRatio: this.aspectRatioValue || NaN,
      autoCropArea: 1,
      restore: false,
      guides: true,
      center: true,
      highlight: true,
      cropBoxMovable: true,
      cropBoxResizable: true,
      toggleDragModeOnDblclick: false,
      responsive: true,
      checkOrientation: true,
      minContainerWidth: 200,
      minContainerHeight: 200
    }

    this.cropper = new Cropper(this.previewTarget, options)
  }

  crop() {
    if (!this.cropper) return

    const canvas = this.cropper.getCroppedCanvas({
      minWidth: this.minWidthValue,
      minHeight: this.minHeightValue,
      maxWidth: 4096,
      maxHeight: 4096,
      fillColor: '#fff',
      imageSmoothingEnabled: true,
      imageSmoothingQuality: 'high'
    })

    canvas.toBlob((blob) => {
      // Create a new File object with the cropped image
      const fileName = this.originalFile.name
      const croppedFile = new File([blob], fileName, { type: this.originalFile.type })

      // Create a DataTransfer to set the file input value
      const dataTransfer = new DataTransfer()
      dataTransfer.items.add(croppedFile)
      this.inputTarget.files = dataTransfer.files

      // Hide the cropper
      this.cropperContainerTarget.classList.add('hidden')

      // Destroy the cropper instance
      if (this.cropper) {
        this.cropper.destroy()
        this.cropper = null
      }

      // Dispatch event to notify form of change
      this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }))
    }, this.originalFile.type)
  }

  cancel() {
    // Clear the file input
    this.inputTarget.value = ''

    // Hide the cropper
    this.cropperContainerTarget.classList.add('hidden')

    // Destroy the cropper instance
    if (this.cropper) {
      this.cropper.destroy()
      this.cropper = null
    }
  }

  reset() {
    if (this.cropper) {
      this.cropper.reset()
    }
  }

  rotate(event) {
    const degrees = parseInt(event.currentTarget.dataset.degrees) || 90
    if (this.cropper) {
      this.cropper.rotate(degrees)
    }
  }

  flip(event) {
    const direction = event.currentTarget.dataset.direction || 'horizontal'
    if (this.cropper) {
      if (direction === 'horizontal') {
        const scaleX = this.cropper.getData().scaleX || 1
        this.cropper.scaleX(-scaleX)
      } else {
        const scaleY = this.cropper.getData().scaleY || 1
        this.cropper.scaleY(-scaleY)
      }
    }
  }

  zoom(event) {
    const ratio = parseFloat(event.currentTarget.dataset.ratio) || 0.1
    if (this.cropper) {
      this.cropper.zoom(ratio)
    }
  }
}
