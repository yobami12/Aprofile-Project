#!/bin/bash
pha() {
    uniq -c ~/pha.txt | grep -v '1' > ~/doublenames.txt
    sendmail ayobami.agbe-davies@arrivealiveltd.com < doublenames.txt
}
pha

