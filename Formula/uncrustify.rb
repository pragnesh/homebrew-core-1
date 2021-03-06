class Uncrustify < Formula
  desc "Source code beautifier"
  homepage "https://uncrustify.sourceforge.io/"
  url "https://github.com/uncrustify/uncrustify/archive/uncrustify-0.65.tar.gz"
  sha256 "45e954cd207ee4f6531d72ece27554ef4e0e9f64c912b523bc80ad6a36404110"
  head "https://github.com/uncrustify/uncrustify.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "7aa15a6b8463dbad2c015cacf286d3629a411814259e815f11bc71e301eab66b" => :sierra
    sha256 "f3ebd4ba2c354d2d6f739524ef2a4016063f318aa0eef6bd39e1c2490076fda5" => :el_capitan
    sha256 "5ebbc8e9fde8672c6f7875b63c494378fef7c3fb84d518a1ff0fb32ea18a3738" => :yosemite
    sha256 "99d85c7c871a3212b0128e4f52669bad4e5ea3ded06792c3d0c4e215e9dd7b1b" => :x86_64_linux
  end

  depends_on "cmake" => :build

  def install
    mkdir "build" do
      system "cmake", "..", *std_cmake_args
      system "make", "install"
    end
    doc.install (buildpath/"documentation").children
  end

  test do
    (testpath/"t.c").write <<-EOS.undent
      #include <stdio.h>
      int main(void) {return 0;}
    EOS
    expected = <<-EOS.undent
      #include <stdio.h>
      int main(void) {
      \treturn 0;
      }
    EOS

    system "#{bin}/uncrustify", "-c", "#{doc}/htdocs/default.cfg", "t.c"
    assert_equal expected, File.read("#{testpath}/t.c.uncrustify")
  end
end
