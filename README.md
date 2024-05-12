![](https://github.com/senselogic/GIP/blob/master/LOGO/gip.png)

# Gip

Batch git pusher.

## Installation

Install the [DMD 2 compiler](https://dlang.org/download.html) (using the MinGW setup option on Windows).

Build the executable with the following command line :

```bash
dmd -m64 gip.d
```

## Command line

```bash
gip <branch name> <maximum commit size> <commit message>
```

### Examples

```bash
gip master 100 "added initial version"
```

Push changes on the master branch using commits of maximum 100 megabytes.

## Version

1.0

## Author

Eric Pelzer (ecstatic.coder@gmail.com).

## License

This project is licensed under the GNU General Public License version 3.

See the [LICENSE.md](LICENSE.md) file for details.
