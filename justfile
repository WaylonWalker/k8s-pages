version := `cat version`

version:
    #!/bin/bash
    echo {{ version }}

release:
   #!/bin/bash
   ./scripts/get_release_notes.py "{{ version }}" > release_notes.tmp
   helm package helm-chart
   gh release create "v{{ version }}" \
       --title "v{{version}}" \
       --notes-file release_notes.tmp \
       k8s-pages-{{ version }}.tgz
   rm release_notes.tmp
