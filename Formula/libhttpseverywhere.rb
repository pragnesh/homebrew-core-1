class Libhttpseverywhere < Formula
  desc "Bring HTTPSEverywhere to desktop apps"
  homepage "https://github.com/gnome/libhttpseverywhere"
  url "https://download.gnome.org/sources/libhttpseverywhere/0.4/libhttpseverywhere-0.4.7.tar.xz"
  sha256 "987e55b25050fef6be9b8b029df3057140073c5a30f0390d5a209e4e9c063882"

  bottle do
    cellar :any
    sha256 "27c069fe35243e8790dfabc710bcfdd54db3ee49ffd92fc8aa51026d16793139" => :sierra
    sha256 "66462b4cd59061bd7ba3d57ee1a2c38306c64a48655f1f6ce0e1c5a316d750ad" => :el_capitan
    sha256 "cd90d0fb2ccc01feba2b4f35c370536cd2c955af82913362b98e033fb18cc6fa" => :yosemite
    sha256 "09f366a03e970ec1ffed3ce158ec340b8fbf020477bd17f94cdd8b2fb7a886ba" => :x86_64_linux
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "vala" => :build
  depends_on "pkg-config" => :build
  depends_on "glib"
  depends_on "json-glib"
  depends_on "libsoup"
  depends_on "libgee"
  depends_on "libarchive"

  def install
    mkdir "build" do
      system "meson", "--prefix=#{prefix}", ".."
      system "ninja"
      system "ninja", "test"
      system "ninja", "install"
    end

    dir = [Pathname.new("#{lib}64"), lib/"x86_64-linux-gnu"].find(&:directory?)
    unless dir.nil?
      mkdir_p lib
      system "/bin/mv", *Dir[dir/"*"], lib
      rmdir dir
      inreplace Dir[lib/"pkgconfig/*.pc"], %r{lib64|lib/x86_64-linux-gnu}, "lib"
    end
  end

  test do
    (testpath/"test.c").write <<-EOS.undent
      #include <httpseverywhere.h>

      int main(int argc, char *argv[]) {
        GType type = https_everywhere_context_get_type();
        return 0;
      }
    EOS
    ENV.libxml2
    gettext = Formula["gettext"]
    glib = Formula["glib"]
    json_glib = Formula["json-glib"]
    libarchive = Formula["libarchive"]
    libgee = Formula["libgee"]
    libsoup = Formula["libsoup"]
    pcre = Formula["pcre"]
    flags = (ENV.cflags || "").split + (ENV.cppflags || "").split + (ENV.ldflags || "").split
    flags += %W[
      -I#{gettext.opt_include}
      -I#{glib.opt_include}/glib-2.0
      -I#{glib.opt_lib}/glib-2.0/include
      -I#{include}/httpseverywhere-0.4
      -I#{json_glib.opt_include}/json-glib-1.0
      -I#{libarchive.opt_include}
      -I#{libgee.opt_include}/gee-0.8
      -I#{libsoup.opt_include}/libsoup-2.4
      -I#{pcre.opt_include}
      -D_REENTRANT
      -L#{gettext.opt_lib}
      -L#{glib.opt_lib}
      -L#{json_glib.opt_lib}
      -L#{libarchive.opt_lib}
      -L#{libgee.opt_lib}
      -L#{libsoup.opt_lib}
      -L#{lib}
      -larchive
      -lgee-0.8
      -lgio-2.0
      -lglib-2.0
      -lgobject-2.0
      -lhttpseverywhere-0.4
      -ljson-glib-1.0
      -lsoup-2.4
      -lxml2
    ]
    flags << "-lintl" if OS.mac?
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
