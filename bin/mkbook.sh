#!/bin/bash
set -e +x

INFILEPATH=$1
shift
EXTRA_ARGS=$*

DIRNAME=`dirname "$INFILEPATH"`
BASENAME=`basename "$INFILEPATH"`
INFILE="$DIRNAME/$BASENAME"
OUTDIR="$DIRNAME/book"

if [ ! -e "$INFILE" ]; then
  echo "Not a file: \`$INFILE\`" && exit 1;
fi;

PDF2PS="pdf2ps"
MIME=`file -b --mime-type "$INFILE"`

case "$MIME" in
  application/pdf)
    PSSRC="$OUTDIR/`basename "$BASENAME" \.pdf`.ps"
    if [ ! -e "$PSSRC" ] || [ "$PSSRC" -ot "$INFILE" ]; then
      echo -n "Writing \`$PSSRC\` ... "
      mkdir -p "$OUTDIR"
      ($PDF2PS "$INFILE" "$PSSRC" && echo "OK") || (echo 'FAILED' && exit 1)
    else
      echo "Using \`$PSSRC\` instead"
    fi
    ;;

  application/postscript)
    mkdir -p "$OUTDIR"
    PSSRC=$INFILE
    ;;
  
  *)
    echo "Don't know how to derive PS from $MIME"
    exit 1
esac

BASENAME=`basename "$PSSRC" \.ps`

cat << EOF
The signature size is the number of sides which will be folded and bound together;
the number given should be a multiple of four.
The default is to use one signature for the whole file.
Extra blank sides will be added if the file does not contain a multiple of four pages.
EOF

PSBOOK_SIGNATURE="go"
while [[ ! "$PSBOOK_SIGNATURE" =~ ^[0-9]*$ ]]; do
  read -p "Size of signature dividible by 4 [default is whole book]: " PSBOOK_SIGNATURE
done

if [ "$PSBOOK_SIGNATURE" != "" ]; then
PSBOOK_SIGNATURE="-s$PSBOOK_SIGNATURE"
fi

BOOKBASENAME="$OUTDIR/$BASENAME.book$PSBOOK_SIGNATURE"

psbook $PSBOOK_SIGNATURE $EXTRA_ARGS "$PSSRC" "$BOOKBASENAME.ps"
psnup -2 -PA4 "$BOOKBASENAME.ps" "$BOOKBASENAME.2page.ps"

ps2pdf "$BOOKBASENAME.2page.ps" "$BOOKBASENAME.2page.pdf"
psselect -o "$BOOKBASENAME.2page.ps" | ps2pdf - "$BOOKBASENAME.2page-odd.pdf"
psselect -e "$BOOKBASENAME.2page.ps" | ps2pdf - "$BOOKBASENAME.2page-even.pdf"

xdg-open "$BOOKBASENAME.2page-odd.pdf"
xdg-open "$BOOKBASENAME.2page-even.pdf"
