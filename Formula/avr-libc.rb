class AvrLibc < Formula
  desc "GNU libc for AVR"
  homepage "https://github.com/avrdudes/avr-libc"
  url "https://github.com/avrdudes/avr-libc/releases/download/avr-libc-2_2_1-release/avr-libc-2.2.1.tar.bz2"
  sha256 "006a6306cbbc938c3bdb583ac54f93fe7d7c8cf97f9cde91f91c6fb0273ab465"

  head "https://github.com/avrdudes/avr-libc.git"

  depends_on "avr-gcc@15"

  def install

    mkdir "build" do
      ENV.prepend_path "PATH", Formula["avr-gcc@15"].bin

      ENV.delete "CFLAGS"
      ENV.delete "CXXFLAGS"
      ENV.delete "LD"
      ENV.delete "CC"
      ENV.delete "CXX"

      system "../configure", "--prefix=#{prefix}", "--host=avr"
      system "make", "install"
    end
  end
end
