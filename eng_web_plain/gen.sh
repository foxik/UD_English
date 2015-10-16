#!/bin/sh

sed 's#</*[^>]*>##g' ../eng_web_tbk/data/answers/source/source_original/*.xml >answers.txt
sed '' ../eng_web_tbk/data/email/source/source_original/*.txt >email.txt
sed 's#</*[^>]*>##g; s/&gt;/>/g; s/&lt;/</g; s/&amp;/\&/g; s/&quot;/"/g' ../eng_web_tbk/data/newsgroup/source/source_original/*.sgm >newsgroup.txt
sed '' ../eng_web_tbk/data/reviews/source/source_original/*.txt >reviews.txt
sed 's#</*[^>]*>##g; s/&gt;/>/g; s/&lt;/</g; s/&amp;/\&/g; s/&quot;/"/g; s/&apos/'"'"'/g' ../eng_web_tbk/data/weblog/source/source_original/*.sgm >weblog.txt

sed '
  s/[’´‘]/'"'"'/g; s/“/"/g; s/”/"/g
  s/Ã³l/A3l/g
  s/Υ/Y/g
  s/[áà]/a/g
  s/é/e/g
  s/ç/c/g
  s/£/L/g
  s/♥/</g
  s/·/*/g
  s/[–—]/-/g
  s/­/ /g
  s/…/./g

  /e-mail address:  janette.elbertson@enron.com/ {N;N;N;N;s/Cafeteria is fine./Cafeteria is fin./; s/I better pass on the Comets game/I better pass on the Comets gam/}
  s/^country taking toll of human lives, properties, etc.$/country taking toll of human lives, properties, etc. ./
  s/Mailing them to the house iis fine./Mailing them to the house iis fin./
  s/The best part is I got my whole bathroom remodeled for about the same price the other company'"'"'/The best part is I got my whole bathroom remodeled for about the same price the other compan'"'"'/

  /^recette de cuisine | skype | tablature guitare | tarot | telecharger/,/^de la soupe recette de soupe/d

' -i *.txt
