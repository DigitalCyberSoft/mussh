class Mussh < Formula
  desc "Multi-host SSH command execution tool"
  homepage "https://github.com/DigitalCyberSoft/mussh"
  url "https://github.com/DigitalCyberSoft/mussh/archive/v1.2.3.tar.gz"
  sha256 "39340414c6098e757c8e0af8310103d189c0af8e4796d9baf0331c858ae713b9"
  license "GPL-2.0"
  head "https://github.com/DigitalCyberSoft/mussh.git", branch: "main"

  depends_on "bash"

  def install
    # Install the main script
    bin.install "mussh"
    
    # Install man page
    man1.install "mussh.1"
    
    # Install bash completion
    bash_completion.install "mussh-completion.bash" => "mussh"
    
    # Install documentation
    doc.install "README.md", "CHANGES", "EXAMPLES", "INSTALL"
  end

  test do
    # Test that the script runs and shows version
    assert_match version.to_s, shell_output("#{bin}/mussh -V")
    
    # Test that help works
    assert_match "Usage:", shell_output("#{bin}/mussh --help")
    
    # Test basic functionality (dry run)
    system "#{bin}/mussh", "--help"
  end

  def caveats
    <<~EOS
      mussh has been installed with Homebrew.
      
      For bash completion support, add the following to your shell configuration:
        echo 'source "$(brew --prefix)/etc/bash_completion.d/mussh"' >> ~/.bashrc
      
      Or for zsh users:
        echo 'autoload -U +X bashcompinit && bashcompinit' >> ~/.zshrc
        echo 'source "$(brew --prefix)/etc/bash_completion.d/mussh"' >> ~/.zshrc
      
      Examples:
        mussh host1 host2 host3 "uptime"
        mussh -H hostfile.txt -c "df -h"
        mussh server*.example.com "ps aux | grep nginx"
      
      For more information, see: man mussh
    EOS
  end
end