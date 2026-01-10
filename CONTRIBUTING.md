# Contributing to ContextualSDK

Thank you for your interest in contributing! We want to make it as easy as possible for you to get involved.

## How to Contribute

1.  **Fork the repository** on GitHub.
2.  **Clone your fork** locally:
    ```bash
    git clone https://github.com/your-username/ContextualSDK.git
    ```
3.  **Create a branch** for your feature or bug fix:
    ```bash
    git checkout -b my-new-feature
    ```
4.  **Make changes**.
    *   Ensure you maintain `ContextualBrain` protocol compliance.
    *   Use `Logger.brain` / `Logger.ui` for any new logging.
    *   Verify your changes using the `DebugView` side-by-side comparison.
5.  **Commit your changes** with a clear message.
6.  **Push to your fork**:
    ```bash
    git push origin my-new-feature
    ```
7.  **Submit a Pull Request**.

## Reporting Bugs

If you find a bug, please open an issue describing:
- What happened.
- What you expected to happen.
- Steps to reproduce.
- iOS/Device version.

## Code Style

- Use SwiftLint rules (default configuration).
- Ensure all public APIs are documented.
- Prefer `struct` over `class` where possible.
