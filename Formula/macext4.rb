class Macext4 < Formula
  include Language::Python::Virtualenv

  desc "CLI to read, list and extract files from Linux ext2/ext3/ext4 disks"
  homepage "https://github.com/helloworldkr/MacExt4"
  # Upstream has not cut a tagged release yet, so this pins to a known-good
  # commit on main. Bump both `revision` and `version` together when updating.
  url "https://github.com/helloworldkr/MacExt4.git",
      revision: "2480ae82028d3f8add3170df2b4ec2e18f47158e"
  version "0.1.0-2480ae8"
  license "MIT"
  head "https://github.com/helloworldkr/MacExt4.git", branch: "main"

  depends_on "python@3.13"
  # Provides `debugfs`/`mke2fs`, used as an optional fallback engine and by
  # the `create-demo` command. Not required for normal read-only browsing.
  depends_on "e2fsprogs"

  # Pure-Python wheel for github.com/Eeems/python-ext4 (the "ext4" PyPI
  # package). Its sdist builds via Nuitka, which we don't need since the
  # project also ships a plain, cross-platform wheel.
  resource "ext4" do
    url "https://files.pythonhosted.org/packages/e4/9b/32ffae636b8ad3a7568ec810ca4c106f4c9ba3d3bde1621a062d027155e0/ext4-1.4.1-py3-none-any.whl"
    sha256 "a92ce289160162d6e68a9ccc9c717184bfa65c1b547de6bd801b248bd98daede"
  end

  resource "cachetools" do
    url "https://files.pythonhosted.org/packages/bf/0f/f897abe4ea0a8c408ae65c8c83bffab4936ad65d6032d4fb4cd35bbdc3ee/cachetools-7.1.1-py3-none-any.whl"
    sha256 "0335cd7a0952d2b22327441fb0628139e234c565559eeb91a8a4ac7551c5353d"
  end

  resource "crcmod" do
    url "https://files.pythonhosted.org/packages/6b/b0/e595ce2a2527e169c3bcd6c33d2473c1918e0b7f6826a043ca1245dd4e5b/crcmod-1.7.tar.gz"
    sha256 "dc7051a0db5f2bd48665a990d3ec1cc305a466a77358ca4492826f41f283601e"
  end

  def install
    venv = virtualenv_create(libexec, "python3.13")
    venv.pip_install resources

    # Upstream hardcodes the Apple Silicon Homebrew prefix for its optional
    # debugfs-based fallback engine and its demo-image generator, so it
    # silently loses that functionality under an Intel/`/usr/local` Homebrew
    # install. Point both at this Homebrew's actual e2fsprogs instead.
    debugfs = Formula["e2fsprogs"].opt_sbin/"debugfs"
    mke2fs = Formula["e2fsprogs"].opt_sbin/"mke2fs"
    inreplace "reader.py", "/opt/homebrew/opt/e2fsprogs/sbin/debugfs", debugfs
    inreplace "sample_generator.py" do |s|
      s.gsub! "/opt/homebrew/opt/e2fsprogs/sbin/debugfs", debugfs
      s.gsub! "/opt/homebrew/opt/e2fsprogs/sbin/mke2fs", mke2fs
    end

    pkgdir = libexec/"macext4"
    pkgdir.install %w[cli.py reader.py disk_detector.py sample_generator.py]

    (bin/"macext4").write <<~SH
      #!/bin/bash
      exec "#{libexec}/bin/python3" "#{pkgdir}/cli.py" "$@"
    SH
    (bin/"macext4").chmod 0755
  end

  def caveats
    <<~EOS
      This formula installs only the `macext4` command-line tool (the
      `cli.py` interface upstream documents as "Method 4: Terminal Command
      Line"): `disks`, `info`, `ls`, `cat`, `extract`, `create-demo`.

      The desktop app (LinuxSSDReader.app), the web dashboard (run.sh) and
      Finder mounting (mount_finder.sh) are not installed: upstream ships no
      requirements.txt/pyproject.toml pinning their extra dependencies
      (fastapi, uvicorn, pywebview, pyobjc) or, for Finder mounting,
      `fuse-t`. To use those, clone the repo directly and follow its README.

      Since upstream has not tagged a release, this formula tracks a pinned
      commit rather than a version number.
    EOS
  end

  test do
    system bin/"macext4", "create-demo"
    image = testpath/"sample_linux_disk.img"
    assert_predicate image, :exist?

    output = shell_output("#{bin}/macext4 info #{image}")
    assert_match "Linux Filesystem Information", output
  end
end
