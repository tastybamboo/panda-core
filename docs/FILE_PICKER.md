# Unified File Picker

## Context

Panda CMS currently has 7+ separate file upload pathways (gallery upload, EditorJS image, EditorJS file attachment, OG image on pages, OG image on posts, form builder drag-drop, form builder cropper) with no way to browse or reuse existing files. Users must re-upload images even when they already exist in the gallery.

This plan consolidates file management into panda-core as a unified file picker modal that works across all contexts: form fields, EditorJS, and the gallery itself.

## Goals

- Browse and select existing files from any upload context
- Upload new files with categorisation
- Filter files by type (images, documents, etc.) and category
- Select existing image variants or re-crop for a new use case
- Integrate with both form fields and EditorJS
- Keep all file management in panda-core (no separate gem)

## Architecture

### Component structure

```
panda-core/
├── app/
│   ├── components/panda/core/admin/
│   │   ├── file_picker_component.rb          # Main modal component
│   │   ├── file_picker_component.html.erb
│   │   ├── file_picker_grid_component.rb     # Reusable file grid (shared with gallery)
│   │   └── file_picker_grid_component.html.erb
│   ├── controllers/panda/core/admin/
│   │   └── files_controller.rb               # Moved from panda-cms
│   └── javascript/panda/core/controllers/
│       └── file_picker_controller.js          # Stimulus controller
```

### Component: `FilePickerComponent`

A modal with two tabs: **Browse** and **Upload**.

```ruby
# Rendered inline on any page that needs it
<%= render Panda::Core::Admin::FilePickerComponent.new(
  accept: "image/*",           # Filter by MIME type
  category: "page-images",     # Pre-filter category
  with_cropper: true,          # Enable crop after selection
  aspect_ratio: 1.91,          # Crop aspect ratio
  min_width: 1200,             # Minimum dimensions
  min_height: 630,
  picker_id: "og-image-picker" # Unique ID for multiple pickers on one page
) %>
```

### Stimulus controller: `file-picker`

Manages modal state, tab switching, file selection, and event dispatch.

```
Values:
  accept         — MIME type filter (e.g. "image/*")
  category       — Pre-selected category slug
  filesUrl       — Endpoint for fetching file grid (Turbo Frame)
  uploadUrl      — Endpoint for uploading files
  withCropper    — Boolean, enable crop step
  aspectRatio    — Float, crop aspect ratio
  minWidth       — Integer, minimum crop width
  minHeight      — Integer, minimum crop height

Targets:
  modal, backdrop, browseTab, uploadTab,
  browseContent, uploadContent,
  fileGrid, searchInput, categoryFilter,
  cropperModal, cropperImage,
  altTextInput, altTextStep,
  selectedPreview, hiddenInput

Actions:
  open(event)           — Open modal, triggered by form field button
  close()               — Close modal
  switchTab(event)      — Toggle browse/upload
  selectFile(event)     — Highlight file, show details
  confirmSelection()    — Proceed to post-selection workflow
  search(event)         — Filter grid by filename/description (debounced)
  filterCategory(event) — Filter by category
  filterType(event)     — Filter by MIME type
  upload(event)         — Handle file upload, refresh grid
  openCropper(event)    — Open crop step for selected image
  cropConfirm()         — Save cropped version, proceed to alt text
  setAltText(event)     — Update alt text for this selection
  confirm()             — Final confirm, dispatch event with all data

Post-selection workflow:
  1. Select/upload file
  2. Crop (if with_cropper enabled and file is an image)
  3. Alt text prompt (pre-filled from blob metadata if exists)
  4. Preview final result
  5. Confirm → dispatch event

Outbound event:
  file-picker:selected  — CustomEvent with detail:
    { blobId, signedId, url, filename, contentType, width, height, alt }
```

### Form builder integration

Extend `Panda::Core::FormBuilder#file_field` with a `with_picker` option:

```ruby
# In a form
f.file_field :og_image, {
  with_picker: true,         # Adds "Browse files" button
  with_cropper: true,        # Crop step after browse or upload
  aspect_ratio: 1.91,
  min_width: 1200,
  min_height: 630,
  accept: "image/png,image/jpeg,image/webp",
  picker_category: "page-images"
}
```

This renders:
1. The existing drag-drop upload zone (for quick direct uploads)
2. A "Browse existing files" button that opens the picker modal
3. A hidden input for the selected blob's signed ID
4. A preview area showing the selected/uploaded image

The form builder listens for `file-picker:selected` and populates the hidden input + preview.

### EditorJS integration

EditorJS image and file tools currently POST directly to the files endpoint. Two integration approaches:

**Option A — Custom tool button (recommended)**
Add a "Browse files" button to the EditorJS image tool toolbar. Clicking it opens the file picker modal. On selection, the tool receives the URL and inserts it as if uploaded.

**Option B — Custom EditorJS tool**
Create a `PandaImageTool` that extends the default image tool with browse capability built in.

Both approaches dispatch the same `file-picker:selected` event.

### Server endpoints

The existing `FilesController` gains a new action for modal content:

```ruby
# GET /admin/files/picker?accept=image/*&category=page-images
def picker
  # Same filtering as index but rendered in a Turbo Frame
  # for embedding in the picker modal
end
```

### Variant selection and re-cropping

When selecting an existing image that has variants:

1. Show the original and all existing variants in the detail panel
2. User can select an existing variant (e.g. `og_share` at 1200×630)
3. Or click "Crop" to create a new variant with CropperJS
4. New crops are saved as variants on the original blob

```
┌─────────────────────────────────────┐
│  Selected: hero-image.jpg           │
│  Original: 2400×1600                │
│                                     │
│  Existing variants:                 │
│  ┌──────┐ ┌──────┐ ┌──────┐       │
│  │1200× │ │ 800× │ │ 400× │       │
│  │ 630  │ │ 400  │ │ 200  │       │
│  │[Use] │ │[Use] │ │[Use] │       │
│  └──────┘ └──────┘ └──────┘       │
│                                     │
│  [Crop new variant]  [Use original] │
└─────────────────────────────────────┘
```

## Migration plan

### Phase 1 — Foundation (panda-core)
1. Move `FilesController` from panda-cms to panda-core
2. Move file gallery views and components to panda-core
3. Add engine routes for files in panda-core
4. Update panda-cms to mount/use panda-core's files routes
5. Verify existing gallery still works

### Phase 2 — File picker modal
1. Build `FilePickerComponent` (ViewComponent) with browse + upload tabs
2. Build `file-picker` Stimulus controller (modal, tabs, selection, infinite scroll)
3. Add `picker` endpoint to `FilesController` (Turbo Frame response)
4. Add type filtering (images, documents, audio, video) and category filtering
5. Add search by filename and description
6. Integrate upload directly into the picker (Upload tab replaces separate upload flows)
7. Integrate CropperJS into the picker for post-selection cropping

### Phase 3 — Form builder integration
1. Add `with_picker` option to `FormBuilder#file_field`
2. Wire up `file-picker:selected` event to populate form fields
3. Pass cropper options through to picker (aspect_ratio, min dimensions)
4. Update OG image fields in pages and posts to use picker
5. Support upload-only mode (no browse tab) for non-admin contexts

### Phase 4 — Permissions
1. Create `FileCategoryPermission` model (role or user → category → capabilities)
2. Filter browse results by view permission
3. Filter upload categories by upload permission
4. Enforce modify/delete permissions in controller
5. Adaptive UI: hide browse tab when no view permissions, hide upload tab when no upload permissions

### Phase 5 — EditorJS integration
1. Add "Browse files" button to panda-editor image tool
2. Wire picker selection to EditorJS image insertion
3. Add browse option to file attachment tool
4. Test with existing editor content workflows

### Phase 6 — Variant management
1. Show existing variants when selecting an image
2. Allow selecting a specific variant
3. Allow creating new crop variants from the picker
4. Variant metadata (purpose, dimensions, created by)

## Type filtering

Add a `content_type_group` scope to blob queries:

```ruby
CONTENT_TYPE_GROUPS = {
  "images"    => %w[image/png image/jpeg image/jpg image/webp image/gif image/svg+xml],
  "documents" => %w[application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document],
  "audio"     => %w[audio/mpeg audio/wav audio/ogg],
  "video"     => %w[video/mp4 video/webm video/ogg]
}.freeze

scope :by_content_type_group, ->(group) {
  types = CONTENT_TYPE_GROUPS[group]
  where(content_type: types) if types
}
```

## Testing strategy

- **Component specs**: FilePickerComponent renders correctly with various options
- **System specs**: Open picker, browse files, select one, confirm selection populates form
- **System specs**: Upload via picker, verify file appears in grid and can be selected
- **System specs**: Crop workflow — select image, crop, confirm cropped version
- **Request specs**: Picker endpoint returns filtered results
- **EditorJS specs**: Browse button opens picker, selection inserts image into editor

## Resolved decisions

1. **Search**: Filename and description, plus filter by category
2. **Pagination**: Infinite scroll
3. **Multi-select**: Single select only for v1
4. **Permissions**: Category-based permissions — view/upload/modify/delete per category, or "All Categories". File browsing respects these permissions.
5. **Drag from picker into editor**: Nice-to-have, not in v1

## Permission model

File permissions are scoped to **file categories**, not individual files. Each
permission grants a combination of capabilities on a category (or all categories):

```ruby
# Example permission structure
Panda::Core::FileCategoryPermission
  belongs_to :role  # or :user
  belongs_to :file_category, optional: true  # nil = all categories

  # Capabilities
  can_view: boolean
  can_upload: boolean
  can_modify: boolean    # rename, re-categorise, edit description
  can_delete: boolean
```

The picker respects these permissions:
- **Browse tab**: Only shows files in categories the user can view
- **Upload tab**: Only shows categories the user can upload to
- **No browse permission at all**: Picker shows upload-only mode (no browse tab)

## Adaptive UI by context

The picker adapts based on the user's permissions and the calling context:

| Context | Browse tab | Upload tab | Crop tools |
|---------|-----------|-----------|------------|
| Admin editing page OG image | Yes (all viewable categories) | Yes | Yes |
| Admin in EditorJS | Yes | Yes | Optional |
| Community user (e.g. avatar, profile) | No (upload-only) | Yes (limited categories) | Yes if applicable |
| User with no upload permission | Yes (browse only) | No | No |

For non-admin contexts (e.g. community features), the picker degrades gracefully
to just an upload box — no browse tab, no category filtering. This keeps the
same component usable across admin CMS and public-facing features.

All users (admin and non-admin) get the same post-selection workflow:
1. **Crop/modify** the image (if cropper is enabled for this field)
2. **Add alt text** — prompted after selection/upload, stored on the blob metadata
3. **Preview** the final result before confirming

Alt text is stored in the blob's metadata hash (`metadata["alt"]`) so it
travels with the file and can be reused when the same file is selected
elsewhere. The picker pre-fills alt text from the blob if it already exists,
and allows the user to override it for this specific usage.

```ruby
# Alt text storage on the blob
blob.metadata["alt"] = "A person reading in a quiet library"

# Usage in views — the picker returns alt text alongside the blob
# event detail: { blobId, signedId, url, filename, contentType, alt }
image_tag url, alt: selected_alt_text
```

## Open questions

1. **Role vs user permissions**: Should file category permissions be role-based (simpler) or per-user (more granular)?
2. **Default permissions**: What should the default permission set be for new categories?
3. **Upload quotas**: Should there be per-user or per-category storage limits?
