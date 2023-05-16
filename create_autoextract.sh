#!/bin/bash

version="1.0.0"
split_token="=====AUTO-EXTRACTER$version====="

echo "Auto-extract file creator, version $version"

if (($# < 2));
then
    echo "Usage: $0 <outfile> <infile1> <infile2> ..."
    exit 1
fi

outfile=$1

echo -ne "
#!/bin/bash
echo \"Auto-extracter script, version $version\"

if ((\$# < 1));
then
    echo \"Usage: \$0 <md5sum>\"
    exit 1
fi

md5=\$1

nr=\$(grep -anhm1 \"^$split_token$\" \$0 2>/dev/null|cut -f1 -d:)

if [ -z \"\$nr\" ] || ((\$nr < 1));
then
    echo \"Error: no split token found in \$0\"
    exit 1
fi
echo \"Found token at line \$nr\"
tail -n +\$((nr+1)) \$0 > tmp_${outfile}.tar
filemd5=\$(md5sum tmp_${outfile}.tar | awk '{print \$1}')

if [ \"\$md5\" != \"\$filemd5\" ];
then
    rm -f tmp_${outfile}.tar
    echo \"Error: File MD5 does not match\"
    exit 1
fi

ar x tmp_${outfile}.tar
rm -f tmp_${outfile}.tar
echo \"finished.\"
exit 0

"  > $outfile

echo "" >> $outfile
echo "$split_token" >> $outfile

shift 1

rm -f tmp_${outfile}.tar
if !(ar q tmp_${outfile}.tar $@);
then
    rm -f $outfile
    echo Failed to archive files
    exit 1
fi

csum=$(md5sum tmp_${outfile}.tar | awk '{print $1}')

echo -ne "MD5: $csum\t$outfile\n" > ${outfile}.md5sum
echo "Md5 sum is $csum"

cat tmp_${outfile}.tar >> $outfile
rm -f tmp_${outfile}.tar

echo "Finished, generated files:"
echo "${outfile}"
echo "${outfile}.md5sum"

