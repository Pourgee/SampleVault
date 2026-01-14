# Contributing to SampleVault

Thank you for your interest in contributing to SampleVault! This document provides guidelines and instructions for contributing.

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/yourusername/SampleVault.git
   ```
3. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Setup

### Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Building the Project

1. Open the project in Xcode:
   ```bash
   cd SampleVault
   open Package.swift
   ```

2. Xcode will automatically resolve Swift Package Manager dependencies

3. Build and run (⌘R)

### Project Structure

```
SampleVault/
├── Sources/
│   ├── Models/           # Data models
│   │   ├── Sample.swift
│   │   ├── Category.swift
│   │   └── Tag.swift
│   ├── Database/         # Database layer
│   │   ├── DatabaseSchema.swift
│   │   └── DatabaseManager.swift
│   ├── Services/         # Business logic
│   │   ├── FileScanner.swift
│   │   └── BookmarkManager.swift
│   └── Views/           # SwiftUI views
│       ├── ContentView.swift
│       ├── SampleListView.swift
│       └── ...
└── Resources/           # Assets and resources
```

## Coding Guidelines

### Swift Style

- Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- Use 4 spaces for indentation
- Maximum line length: 120 characters
- Use meaningful variable and function names

### SwiftUI Best Practices

- Keep views small and focused
- Extract reusable components
- Use `@StateObject` for view models
- Prefer `@EnvironmentObject` for shared state
- Use async/await for asynchronous operations

### Database

- All database operations must use the `DatabaseManager` actor
- Use transactions for bulk operations
- Keep models and database records separate
- Always handle database errors gracefully

### Security

- Use security-scoped bookmarks for all file access
- Never store absolute file paths without bookmarks
- Always check permissions before file operations
- Validate user input

## Making Changes

### Before You Start

1. Check existing issues and PRs
2. Open an issue to discuss major changes
3. Ensure your change aligns with project goals

### Development Process

1. Write clean, documented code
2. Add unit tests for new functionality
3. Update documentation as needed
4. Test thoroughly on macOS 13+ and 14+

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add BPM detection algorithm
fix: resolve crash when importing large folders
docs: update README with new features
refactor: simplify file scanner logic
test: add tests for database manager
chore: update dependencies
```

### Pull Requests

1. Update your branch with latest main:
   ```bash
   git fetch origin
   git rebase origin/main
   ```

2. Push your changes:
   ```bash
   git push origin feature/your-feature-name
   ```

3. Open a pull request with:
   - Clear description of changes
   - Screenshots/videos for UI changes
   - Reference to related issues
   - Test results

4. Address review feedback

## Testing

### Running Tests

```bash
swift test
```

### Manual Testing Checklist

- [ ] Import folder with various audio formats
- [ ] Search and filter samples
- [ ] Play audio samples
- [ ] Tag management
- [ ] Favorites
- [ ] Category navigation
- [ ] Drag-and-drop to Logic Pro
- [ ] App restart (persistence)

## Performance Considerations

- Profile with Instruments for memory/CPU issues
- Keep UI responsive (avoid blocking main thread)
- Use lazy loading for large lists
- Cache expensive operations
- Optimize database queries

## Areas for Contribution

### High Priority

- Audio waveform generation and visualization
- BPM detection algorithm
- Key detection algorithm
- Improved drag-and-drop for Logic Pro
- Keyboard shortcuts and global hotkeys

### Medium Priority

- Advanced search features
- Batch operations UI
- Export/import library
- Sample preview controls (loop, volume)
- Dark mode polish

### Low Priority

- iCloud sync
- Online sample browser
- Audio similarity search
- Multi-language support
- Sample slicing

## Getting Help

- Open an issue for bugs or questions
- Join discussions for feature ideas
- Check existing documentation

## Code Review Process

1. Maintainers will review your PR
2. Address feedback and update PR
3. Once approved, maintainer will merge
4. Your contribution will be credited

## License

By contributing, you agree that your contributions will be licensed under the project's license.

## Recognition

Contributors will be acknowledged in:
- README.md
- Release notes
- About screen (for significant contributions)

---

Thank you for contributing to SampleVault! 🎵
