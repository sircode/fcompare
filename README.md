#### fcompare README.md


# 🧩 fcompare

**fcompare** is a Bash-based command-line tool to compare two folders and generate clear reports on differences. It highlights file additions, deletions, and content changes using `rsync` and `diff`, with both plain-text and HTML output.

---

## 🛠️ Installation

### 🔧 1. Download the script

If cloning from a repository:

```bash
git clone https://github.com/sircode/fcompare.git
cd fcompare
````

Or copy the script manually and save it as `fcompare`.

---

### ⚙️ 2. Make it executable

```bash
chmod +x fcompare
```

---

### 📁 3. Install globally (optional)

To use `fcompare` as a global command:

```bash
sudo mv fcompare /usr/local/bin/
```

Now you can run it from anywhere:

```bash
fcompare -s folderA -d folderB -n my_compare
```

---


### 🧼 6. Uninstall (optional)

```bash
sudo rm /usr/local/bin/fcompare
```

---

## 🚀 Usage

```bash
fcompare -s <source> -d <destination> -n <name> [-o <output folder>] [-x <exclude file>]
```

### Required arguments:

* `-s <source>`: Source folder (e.g. `../dev`)
* `-d <destination>`: Destination folder to compare against (e.g. `../production`)
* `-n <name>`: A short identifier to label the result files (e.g. `dev_VS_production`)


### Optional:

* `-o <output folder>`: Where to store the result files
  Default: current directory
* `-x <exclude file>`: exclude file (e.g. `./project/exclude.txt`)

---

## 📄 Output Files

The following files will be created:

* `RESULT_rsync_dry_<name>.txt`
  List of changed/missing files detected by `rsync --dry-run`

* `DIFFERENCES_<name>.txt`
  Plain-text output showing line-by-line diffs

* `DIFFERENCES_<name>.html`
  Color-coded HTML report (green = added, red = removed)

---

## 🧪 Example

```bash
fcompare -s ../dev -d ../production -n dev_VS_production -o ./out
```

Creates:

```
out/
├── dev_VS_production_RESULT_RSYNC_DRY.txt
├── dev_VS_production_DIFFERENCES.txt
└── dev_VS_production_DIFFERENCES.html
```

## 🖼 Example Output

Here's what your DIFFERENCES.html looks like with `fcompare`:

![image](https://github.com/user-attachments/assets/017af389-1c97-450c-a744-e4aeec1e71dc)

---

## 📁 Excluding files

Add ignore rules to an `exclude.txt` file in the same directory as the script. This is passed to rsync using `--exclude-from=exclude.txt`.

Example `exclude.txt`:

```
*.log
node_modules/
.cache/
```

---

## 📦 Dependencies

Make sure you have the following installed:

* `bash`
* `rsync`
* `diff`
* `php` (required for `make_html_report.php` to generate the HTML output)

---

## ✨ To Do / Ideas

* `--open` to auto-open the HTML report after generation
* `--no-html` to generate text-only output
* Color-coded CLI preview
* Optional recursive vs non-recursive modes

---

## 📄 License

MIT — use it freely, modify it, and share it.

---
