class R < Formula
  desc "Software environment for statistical computing"
  homepage "https://www.r-project.org/"
  url "https://cran.rstudio.com/src/base/R-3/R-3.4.1.tar.gz"
  sha256 "02b1135d15ea969a3582caeb95594a05e830a6debcdb5b85ed2d5836a6a3fc78"

  # Do not remove executable permission from these scripts.
  # See https://github.com/Linuxbrew/linuxbrew/issues/614
  skip_clean "lib/R/bin" unless OS.mac?

  bottle do
    sha256 "ead3a96538eb9bade8990d67cf97bda800107887e0ebd8c0017410fdfa1a244c" => :sierra
    sha256 "93e5072a56a26fc212a9e617d36a786fe807c70e2487551f616484cede800623" => :el_capitan
    sha256 "d7a2ccb1236b46d32ee2ed5a3c43a39b3b4d1c955e58f229ac3f75bfed5d4359" => :yosemite
    sha256 "4b5f810a5bd9a407c9bd40be89c58f8e4104e089e6b73308522d4df37da4dd13" => :x86_64_linux
  end

  depends_on "pkg-config" => :build
  depends_on "gettext"
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "pcre"
  depends_on "readline"
  depends_on "xz"
  depends_on :fortran
  depends_on "openblas" => :optional

  unless OS.mac?
    depends_on "cairo"
    depends_on "curl"
    depends_on "tcl-tk" => :optional
    depends_on :x11 => :recommended
  end

  def install
    # Fix dyld: lazy symbol binding failed: Symbol not found: _clock_gettime
    if MacOS.version == "10.11" && MacOS::Xcode.installed? &&
       MacOS::Xcode.version >= "8.0"
      ENV["ac_cv_have_decl_clock_gettime"] = "no"
    end

    args = [
      "--prefix=#{prefix}",
      "--enable-memory-profiling",
      "--with-lapack",
    ]

    # don't remember Homebrew's sed shim
    args << "SED=/usr/bin/sed" if File.exist?("/usr/bin/sed")

    if OS.linux?
      args << "--libdir=#{lib}" # avoid using lib64 on CentOS
      args << "--enable-R-shlib"
      args << "--with-cairo"
      args << "--with-x" if build.with?("x11")

      # If LDFLAGS contains any -L options, configure sets LD_LIBRARY_PATH to
      # search those directories. Remove -LHOMEBREW_PREFIX/lib from LDFLAGS.
      ENV.remove "LDFLAGS", "-L#{HOMEBREW_PREFIX}/lib"
    elsif OS.mac?
      args << "--without-cairo"
      args << "--with-aqua"
      args << "--without-x"
    end

    if build.with? "openblas"
      args << "--with-blas=-L#{Formula["openblas"].opt_lib} -lopenblas"
      ENV.append "LDFLAGS", "-L#{Formula["openblas"].opt_lib}"
    elsif OS.mac?
      args << "--with-blas=-framework Accelerate"
      ENV.append_to_cflags "-D__ACCELERATE__" if ENV.compiler != :clang
    end

    # Help CRAN packages find gettext and readline
    ["gettext", "readline"].each do |f|
      ENV.append "CPPFLAGS", "-I#{Formula[f].opt_include}"
      ENV.append "LDFLAGS", "-L#{Formula[f].opt_lib}"
    end

    system "./configure", *args
    system "make"
    ENV.deparallelize do
      system "make", "install"
    end

    cd "src/nmath/standalone" do
      system "make"
      ENV.deparallelize do
        system "make", "install"
      end
    end

    # make Homebrew packages discoverable for R CMD INSTALL
    inreplace lib/"R/etc/Makeconf" do |s|
      s.gsub!(/^CPPFLAGS =.*/, "\\0 -I#{HOMEBREW_PREFIX}/include")
      s.gsub!(/^LDFLAGS =.*/, "\\0 -L#{HOMEBREW_PREFIX}/lib")
      s.gsub!(/.LDFLAGS =.*/, "\\0 $(LDFLAGS)")
    end
  end

  def post_install
    short_version =
      `#{bin}/Rscript -e 'cat(as.character(getRversion()[1,1:2]))'`.strip
    site_library = HOMEBREW_PREFIX/"lib/R/#{short_version}/site-library"
    site_library.mkpath
    ln_s site_library, lib/"R/site-library"
  end

  test do
    assert_equal "[1] 2", shell_output("#{bin}/Rscript -e 'print(1+1)'").chomp
  end
end
