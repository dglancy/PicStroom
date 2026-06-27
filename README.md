# PicStroom — iPad

![Logo](https://github.com/dglancy/PicStroom/blob/main/PicStroom-iPad/Default-Landscape~ipad.png)

> **Historical archive.** This repository is read-only. The code is preserved as-is from the final shipped state.

PicStroom was an iPad app that aggregated images from multiple sources into a side-scrolling photo gallery. Users subscribed to "Strooms" — streams of images pulled from RSS/web feeds or Dropbox folders — and browsed them in a single unified view.

**Authors:** Damien Glancy & Jeroen Hermkens  
**Initial commit:** March 2011  
**Language:** Objective-C (manual retain/release, pre-ARC)  
**Target:** iPad, iOS

---

## What It Did

- Displayed multiple Strooms side-by-side in a horizontal strip layout, each scrollable independently
- Synced new images in the background every 10 minutes
- Supported three stroom types: **RSS/web feeds**, **Dropbox folders**, and a built-in **Starred** stroom for favourited images
- Allowed saving images to Dropbox, the camera roll, or Instapaper
- Shipped in two configurations: a free version (capped at 3 strooms, with an In-App Purchase to unlock unlimited) and a paid Pro version

---

## Project Structure

```
PicStroom-iPad/
├── Classes/
│   ├── Sync&Store/          # Data model, sync logic, Core Data entities
│   │   ├── Model/           # Core Data .xcdatamodel
│   │   ├── Stroom.*         # Core Data entity: a single image stream
│   │   ├── Entry.*          # Core Data entity: a feed entry
│   │   ├── Picture.*        # Core Data entity: a downloaded image
│   │   ├── Metadata.*       # Core Data entity: key/value metadata (e.g. starred flag)
│   │   ├── PicStroomManager.*              # CRUD for strooms
│   │   ├── PicStroomAddStroomManager.*     # Creating new strooms
│   │   ├── PicStroomSyncStroomManager.*    # Per-stroom sync orchestration
│   │   ├── PicStroomFeedScanner.*          # RSS/HTML image extraction
│   │   ├── PicStroomImageProcessor.*       # Thumbnail generation
│   │   ├── PicStroomDropboxUploader.*      # Saving images back to Dropbox
│   │   ├── PicStroomInstapaperManager.*    # Instapaper save integration
│   │   ├── PicStroomMetadataManager.*      # Star/unstar images
│   │   ├── PicStroomOrderStroomManager.*   # Stroom reordering
│   │   └── PicStroomStarredPicturesManager.* # Starred stroom management
│   │
│   ├── APIs/                # Vendored third-party libraries
│   │   ├── DropboxSDK/      # Dropbox iOS SDK (OAuth, file listing, download/upload)
│   │   ├── FlurryLib/       # Flurry analytics
│   │   ├── HTML-Parser/     # HTML scraping for image URLs
│   │   ├── HTTP/            # HTTP utilities
│   │   ├── InstapaperKit/   # Instapaper OAuth API client
│   │   ├── KeychainUtils/   # Keychain read/write helpers
│   │   ├── Reachability/    # Network status (Apple sample code)
│   │   ├── RSS-Parser/      # RSS feed parsing
│   │   └── Enhanced-Categories/ # Objective-C category extensions
│   │
│   ├── PicStroomAppDelegate.*          # App lifecycle, Core Data stack, sync timer
│   ├── PicStroomViewController.*       # Root view: stroom strip + control bar
│   ├── PicStroomSupervisor.*           # Per-stroom view controller + tiled thumbnail scroll view
│   ├── PicStroomGalleryController.*    # Browse & add curated strooms from remote plist
│   ├── PicStroomFullScreenPhotoViewController.* # Full-screen image viewer with swipe
│   ├── PicStroomSettingsViewController.*        # App settings panel (popover)
│   ├── PicStroomInAppPurchaseManager.*          # StoreKit IAP for unlimited strooms
│   ├── PicStroomLinkDropboxViewController.*     # Dropbox OAuth link flow
│   ├── PicStroomLinkInstapaperViewController.*  # Instapaper credential entry
│   ├── PicStroomAddStroomsViewController.*      # Add a new web/RSS stroom
│   ├── PicStroomAddDropboxStroomViewController.* # Pick a Dropbox folder as a stroom
│   ├── PicStroomListStroomsViewController.*     # Manage/reorder existing strooms
│   ├── PicStroomListFeedsViewController.*       # Browse feed entries for a stroom
│   ├── PicStroomDetailsViewController.*         # Image detail & actions (star, save, share)
│   ├── PicStroomEmbeddedBrowserViewController.* # In-app web view
│   └── Constants.h                             # All app-wide constants, enums, and #defines
│
├── Resources/               # Images, icons, localisation strings
├── PicStroom-Info.plist     # Bundle metadata
├── Entitlements.plist       # App sandbox entitlements
├── PicStroom.xcodeproj/     # Xcode project
└── main.m                   # UIApplicationMain entry point
```

---

## Key Concepts

**Stroom** — the core data entity. Has a type (`StroomTypeRSS`, `StroomTypeDropbox`, `StroomTypeStarred`), a title, and a state machine (`StroomStateNew` → `StroomStateUpdating` → `StroomStateUptodate`, etc.).

**PicStroomSupervisor** — a `UIViewController` that owns one stroom's horizontal scroll view. Implements a tile-recycling pattern (similar to `UITableView`) to keep memory usage low while displaying potentially hundreds of thumbnails.

**Sync** — the app delegate fires a sync every 10 minutes via `NSTimer`. Each `PicStroomSupervisor` dispatches a `PicStroomSyncStroomManager` operation onto a shared `NSOperationQueue`. Results are broadcast via `NSNotificationCenter` back to the main thread.

**Core Data** — SQLite-backed store at `picstroom.sqlite`. Entities: `Stroom → Entry → Picture`, with `Metadata` key/value pairs attached to pictures (used for the starred flag).

---

## Third-Party Dependencies

| Library | Purpose |
|---|---|
| Dropbox iOS SDK | OAuth authentication, folder listing, file download/upload |
| InstapaperKit | OAuth-based Instapaper API client |
| FlurryLib | Analytics and crash reporting |
| RSS-Parser | RSS 1.0/2.0 feed parsing |
| HTML-Parser | Image URL extraction from arbitrary HTML |
| Reachability | Network reachability detection |
| KeychainUtils | Secure credential storage |

---

## Build Configurations

Two product variants were maintained via `#define` switches in `Constants.h`:

- **IAP Version** (`PICSTROOM_PRO_VERSION = NO`) — free download, limited to 3 strooms, with a StoreKit IAP (`nl.hetissimpel.unlimitedstreams`) to unlock unlimited strooms.
- **Pro Version** (`PICSTROOM_PRO_VERSION = YES`) — paid upfront, no IAP limit.

API keys (Dropbox, Instapaper, Flurry) are redacted to `XXX` in the archived source.
