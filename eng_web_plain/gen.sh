#!/bin/sh

sed 's#</*[^>]*>##g' ../eng_web_tbk/data/answers/source/source_original/*.xml >answers.txt
sed '' ../eng_web_tbk/data/email/source/source_original/*.txt >email.txt
sed 's#</*[^>]*>##g; s/&gt;/>/g; s/&lt;/</g; s/&amp;/\&/g; s/&quot;/"/g' ../eng_web_tbk/data/newsgroup/source/source_original/*.sgm >newsgroup.txt
sed '' ../eng_web_tbk/data/reviews/source/source_original/*.txt >reviews.txt
sed 's#</*[^>]*>##g; s/&gt;/>/g; s/&lt;/</g; s/&amp;/\&/g; s/&quot;/"/g; s/&apos/'"'"'/g' ../eng_web_tbk/data/weblog/source/source_original/*.sgm >weblog.txt

sed '
  s/’/'"'"'/g; s/“/"/g; s/”/"/g;
  s/Déjà/Deja/g
' -i *.txt

cat *.txt >../plain.txt
