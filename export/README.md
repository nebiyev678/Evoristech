# Application exports

Nothing here yet. Put the APEX export of app 102 in this folder.

    App Builder → App 102 → Export / Import → Export → Single File

or, with SQLcl connected:

    apex export -applicationid 102 -split -dir .

Re-export after every working session. This folder is what makes it possible to
write code against the real item, region and process names instead of guessing.

Do not hand-write or hand-edit export files. The `wwv_flow_imp.id(...)` values
are workspace-wide object ids — invented ones can collide with and overwrite
existing objects on import.
