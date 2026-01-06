# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **Documentation Organization**: Moved all 25 markdown documentation files to `docs/` folder for better project structure and overview
- Updated all internal documentation links to reflect new structure
- Updated README.md to reference new docs/ folder location
- Updated verification scripts to check for docs in new location
- **Updated Godot Engine version references**: All documentation now specifies Godot Engine 4.5+ (recommended: 4.5.1) instead of 4.2+
- **Updated Node.js version references**: Standardized to Node.js 20+ across all documentation for consistency

### Removed
- Removed obsolete `net.gd.uid` file from autoload folder (net.gd was previously deprecated)

### Fixed
- Fixed syntax error in `Scenes/Auth/Login.gd` (line 54) - now uses correct GDScript ternary syntax

## [1.0.0] - Previous Release

### Added
- Initial project structure with Godot 4+ frontend and Node.js/Express backend
- Authentication system (login/registration) with JWT
- Game state management via GameState autoload
- API communication layer via Api autoload
- Production system for buildings (well, lumberjack, sandgrube)
- Market system for trading resources
- PostgreSQL database with migrations
- Comprehensive documentation (now in docs/ folder)

### Game Features
- Resource production (water, wood, stone, sand)
- Building construction and upgrades
- Manual production job system (no idle production)
- Resource selling for coins
- Player-to-player market trading
