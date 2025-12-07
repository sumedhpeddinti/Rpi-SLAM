# Contributing to Rpi-SLAM

Thank you for your interest in contributing to the Rpi-SLAM project! We welcome contributions from everyone.

## How to Contribute

### Reporting Bugs

Before creating a bug report, please check the issue list as you might find out that you don't need to create one. When creating a bug report, please include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps which reproduce the problem**
- **Provide specific examples to demonstrate the steps**
- **Describe the behavior you observed after following the steps**
- **Explain which behavior you expected to see instead and why**
- **Include screenshots and animated GIFs if possible**
- **Include your environment details:**
  - Raspberry Pi model
  - OS version
  - Python version
  - OpenCV version
  - Camera type

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- **Use a clear and descriptive title**
- **Provide a step-by-step description of the suggested enhancement**
- **Provide specific examples to demonstrate the steps**
- **Describe the current behavior and the expected behavior**
- **Explain why this enhancement would be useful**

### Pull Requests

- Fill in the required template
- Follow the Python PEP 8 style guide
- Include appropriate test cases
- Update documentation as needed
- End all files with a newline

## Development Setup

### Prerequisites

```bash
# Install development dependencies
pip3 install -r requirements.txt
pip3 install -r dev-requirements.txt
```

### Code Style

We use:
- **Black** for code formatting
- **Flake8** for linting

```bash
# Format code
black rpi_mjpeg_server.py

# Check style
flake8 rpi_mjpeg_server.py
```

### Testing

```bash
# Run tests
pytest tests/

# Run with coverage
pytest --cov=. tests/
```

## Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

Example:
```
Add support for higher resolution streaming

- Implement 1920x1080 support
- Add quality optimization for high resolutions
- Fix memory leak in frame buffer

Fixes #123
```

## Project Structure

```
Rpi-SLAM/
├── rpi_mjpeg_server.py          # Main implementation
├── rpi_picamera_stream.py       # Alternative implementation
├── rpi_gstreamer_stream.sh      # GStreamer version
├── viewer.html                  # Web viewer
├── sum.md                        # Detailed guide
├── requirements.txt             # Python dependencies
├── tests/                       # Unit tests
└── docs/                        # Documentation
```

## Adding New Features

1. Create a new branch: `git checkout -b feature/your-feature-name`
2. Implement your feature
3. Add tests for your feature
4. Update documentation
5. Commit your changes
6. Push to your fork
7. Submit a pull request

## Documentation

When adding new features, please update:
- Code comments and docstrings
- [sum.md](sum.md) for detailed guides
- [README.md](README.md) for overview
- Relevant files in `docs/` folder

## Areas for Contribution

- **Code improvements**: Performance optimization, bug fixes
- **Documentation**: Better guides, more examples
- **Testing**: More test cases, edge case coverage
- **Features**: New streaming options, UI improvements
- **Integration**: ORB-SLAM3 integration improvements
- **Translations**: Multilingual support

## Questions?

Feel free to:
1. Check existing issues and documentation
2. Open a new discussion
3. Contact the maintainers

## License

By contributing to Rpi-SLAM, you agree that your contributions will be licensed under its MIT License.

## Code of Conduct

### Our Pledge

In the interest of fostering an open and welcoming environment, we as contributors and maintainers pledge to making participation in our project and our community a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

Examples of behavior that contributes to creating a positive environment include:
- Using welcoming and inclusive language
- Being respectful of differing opinions, viewpoints, and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

Examples of unacceptable behavior include:
- Harassment of any kind
- Offensive comments
- Personal or political attacks
- Public or private harassment
- Publishing others' private information without permission

### Enforcement

Project maintainers are responsible for clarifying the standards of acceptable behavior and are expected to take appropriate and fair corrective action in response to any instances of unacceptable behavior.

---

Thank you for contributing to Rpi-SLAM! 🚀
