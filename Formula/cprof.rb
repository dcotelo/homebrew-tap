class Cprof < Formula
  desc "Pick which Claude account a directory uses, per repository"
  homepage "https://github.com/dcotelo/cprof"
  url "https://github.com/dcotelo/cprof/archive/refs/tags/cprof--v0.6.1.tar.gz"
  sha256 "91d10f977be9ffbf1eb5c302b3a185baf399a8f439dcd1aa110361eaf26a0597"
  license "MIT"
  head "https://github.com/dcotelo/cprof.git", branch: "main"

  depends_on "jq"
  depends_on :macos

  def install
    # scripts/cprof sources scripts/lib/*.sh relative to the resolved file, so
    # the two have to stay together. It follows symlinks to find them, which is
    # what makes the bin link below work.
    libexec.install "scripts", "statusline", "hooks", "commands"
    bin.install_symlink libexec/"scripts/cprof"
  end

  def caveats
    <<~EOS
      Route `claude` through cprof by adding this to your shell config:

        claude() { eval "$(cprof env)"; command claude "$@"; }

      Then adopt the account you already use and add a second:

        cprof add work --native
        cprof add personal
        cprof login personal

      This formula installs the CLI only. The Claude Code plugin adds the
      SessionStart warning that fires when a directory expects a different
      account, the /profile command, and the statusline badge:

        claude plugin marketplace add dcotelo/cprof
        claude plugin install cprof@dcotelo
    EOS
  end

  test do
    assert_match "cprof #{version}", shell_output("#{bin}/cprof version")

    # env never exits non-zero and always prints one assignment: a broken
    # install must degrade to stock Claude Code, never to a broken shell.
    output = shell_output("CPROF_CONFIG=#{testpath}/none.json #{bin}/cprof env")
    assert_match "CLAUDE_CONFIG_DIR", output

    # The bin entry is a symlink into libexec; this asserts it still finds its
    # library directory through it, rather than printing an unset that a shell
    # function would eval into the wrong account.
    refute_match "cannot locate lib directory",
                 shell_output("#{bin}/cprof version 2>&1")
  end
end
