class Netpbm < Formula
  desc "Image manipulation"
  homepage "https://netpbm.sourceforge.io/"
  # Maintainers: Look at https://sourceforge.net/p/netpbm/code/HEAD/tree/
  # for stable versions and matching revisions.
  if MacOS.version >= :sierra
    url "https://svn.code.sf.net/p/netpbm/code/stable", :revision => 2985
  else
    url "http://svn.code.sf.net/p/netpbm/code/stable", :revision => 2985
  end
  version "10.73.11"
  version_scheme 1

  head "https://svn.code.sf.net/p/netpbm/code/trunk"

  bottle do
    cellar :any
    sha256 "f84a211e48ba54ae9469acf667ff82bd67f36621f21e77178e5e5471dcead5c2" => :sierra
    sha256 "6fbd4085a53f04b1c04cbbe6baa51ad7b74ce085ad13280dc16657f69785a5a0" => :el_capitan
    sha256 "f55cef11f173fa94a21eb3b8e7d8853462b20ae02361909aa7578a8859e4f1de" => :yosemite
    sha256 "173dda90394c209133748b569c9ec9f0adafb51a7f7940f3efa1db72786db76b" => :x86_64_linux
  end

  depends_on "libtiff"
  depends_on "jasper"
  depends_on "jpeg"
  depends_on "libpng"
  unless OS.mac?
    depends_on "flex"
    depends_on "zlib"
  end

  def install
    cp "config.mk.in", "config.mk"

    inreplace "config.mk" do |s|
      s.remove_make_var! "CC"
      if OS.linux?
        s.change_make_var! "CFLAGS_SHLIB", "-fPIC"
      elsif OS.mac?
        s.change_make_var! "CFLAGS_SHLIB", "-fno-common"
        s.change_make_var! "NETPBMLIBTYPE", "dylib"
        s.change_make_var! "NETPBMLIBSUFFIX", "dylib"
        s.change_make_var! "LDSHLIB", "--shared -o $(SONAME)"
      end
      s.change_make_var! "TIFFLIB", "-ltiff"
      s.change_make_var! "JPEGLIB", "-ljpeg"
      s.change_make_var! "PNGLIB", "-lpng"
      s.change_make_var! "ZLIB", "-lz"
      s.change_make_var! "JASPERLIB", "-ljasper"
      s.change_make_var! "JASPERHDR_DIR", "#{Formula["jasper"].opt_include}/jasper"
    end

    ENV.deparallelize
    system "make"
    system "make", "package", "pkgdir=#{buildpath}/stage"

    cd "stage" do
      inreplace "pkgconfig_template" do |s|
        s.gsub! "@VERSION@", File.read("VERSION").sub("Netpbm ", "").chomp
        s.gsub! "@LINKDIR@", lib
        s.gsub! "@INCLUDEDIR@", include
      end

      prefix.install %w[bin include lib misc]
      # do man pages explicitly; otherwise a junk file is installed in man/web
      man1.install Dir["man/man1/*.1"]
      man5.install Dir["man/man5/*.5"]
      lib.install Dir["link/*.a"]
      lib.install Dir["link/*.dylib"] if OS.mac?
      (lib/"pkgconfig").install "pkgconfig_template" => "netpbm.pc"
    end

    (bin/"doc.url").unlink
  end

  test do
    fwrite = Utils.popen_read("#{bin}/pngtopam #{test_fixtures("test.png")} -alphapam")
    (testpath/"test.pam").write fwrite
    system "#{bin}/pamdice", "test.pam", "-outstem", testpath/"testing"
    assert File.exist?("testing_0_0.")
  end
end
