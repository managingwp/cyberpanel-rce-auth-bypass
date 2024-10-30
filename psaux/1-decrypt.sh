#!/bin/bash

######################################################################################
#                    LeakIX PSAUX CyberPanel Ransom campaign decrypter               #
#                                                                                    #
#                    You have been blessed by PSAUX                                  #
#                                                                                    #
#                    All your files can be decrypted.                                #
#                                                                                    #
#                                                                                    #
# Telegram: @psauxsec                                                                #
#                                                                                    #
# Fun must be made on that channel for weak crypto,                                  #
#                                                                                    #
#  Ransomware Rushed by PSAUX                                                        #
#                                                                                    #
######################################################################################

# WARNING, WE ARE AWARE OF MULTIPLE ENCRYPTION ATTACKS. THIS SCRIPT WORKS WHEN YOUR FILES ARE ENCRYPTED WITH .psaux EXTENSION
# WARNING, ALWAYS WORK ON A COPY OF YOUR DATA, ENCRYPTED OR NOT
# WARNING, THIS SCRIPT WILL RESTORE FILES FROM THE TIME THEY WERE ENCRYPTED, BACKUP ANY CHANGES MADE AFTER THE HACK


### Fail the script if anything's wrong, that's people's data we're dealing with
set -e

echo "Running PSAUX CyberPanel decrypter..."

### Master key gently provided by PSAUX

MASTER_KEY="-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDFiVLFtwUUcizD
4gUkRJayJQFAW79ZojEE8YLLnfF5x5Z1A2hP/qT21LMOmvMz03gu9Jn3G+Iby8cx
4OtvUDuG0tx+Cbq2u2lJj+ZmL11mMMbbR9aTWZhGmdVY3T9X2dObJSV94F5Itd3s
SSf4A+Osb2Ea2Ci6BCK6mCXw7Qrwr4epWuwUiZ2JqfX3Iv5oLmwLOKF/nOM0XzIp
fyopK10C/Di5erPBIAV2SYQh7sZ0JKRH7biL+s9dPM2e+8Ckuvkqkb1O1lIpOh8j
8N/dxn/y9w53KGYsSOaN0ZHseBNCbIwW1s22q4iG/p5d+UG+kTRc8HqdmENw65Vv
S8ycNPnZAgMBAAECggEBAIRgjZ7AEuBrz0IKIqX2bQK/N8J4eZhI0A7fBmcL1npk
3ZhXCz2oicZ8Le6Yumi9y6mz88Yc4n78JeZwM3aqTuoAPxEb1guFNn68t4s9LJtC
DtF+p/ahMSIHD2l5A20NJfivgRuFE8ooTqt9LxLPEHFLRsjlmQ1nnhprweleAVnf
Kl66kGZa/lAF99P7g4+3/hukVHMRPKCCEmc/77bgIw7gXe/lRutFReraGdziGky3
VkDIx7MUdGp+n4Hf4iqtUzpinN0IlvgFiMvH4aoAr5vDHitEOGuaovyeA51c2qJw
RGIAJPgWdaKj7yJl65uLmZPLxel2MCrOHqn8jv1zzw0CgYEA47kmxIT9JXoH3r0y
kxxgzR+W9FiIM+MP01F2IfoELNXP0yCZ5sSQ2p+gT61wwTZWvzmzkE8w+AcsJirs
ntlTyG5pJNQYTBSJW9lRoXykpgyRyhpEy7OES1NlWslWM2kthJQ/XZiAfaJ504ZL
cw4q3PhvcSofknRyYpLEYJ8nyg8CgYEA3hCYarpOrDxN55TB5rdU7adX4b6faK2z
NuV/grn8qqpG4nB1jj8tQI5q1NTzBe4ngLdJ6+uyGln7WvIr0llaCnhJo2Yp4EhX
5vNw3cKSdlJynZtp3k9FidhMfjrzzX3d7q7n3BFk/UgUPMRDM85q3qZzSEqLy3wI
G/WCqmMNhZcCgYBOFKMFSPAflHr0VXzs0hMi4gz5VQ3GdLltZIYT2kzqLpmms4vx
gz6Dp63pA/ggV4hg4uD9vxl0QclSgO9G/A9tLuZgWVTHaVc7pgUGUN2HjdHDMUSb
b78RsNOU0Gn9ELgpuEcNyYdtDHOnImnmVlo+D/TuIVpX9hNuVxJ8arXS4wKBgC5I
MSwVVm5JR0db1qnaTeYWOZfAHgM4KKDpZhD96G49fPaWz7ls62aICDYBiAEVaMBH
8y0re3xIgr2quX1myABkn5xhn5qyGTf2RvDBK7tjZaX5jTAbP3gCT7cDXGrYr9ee
No7ERVMQob8kfIkgnV94O5C2kLpBSINjQO94I4pTAoGASChZYdSvI46zNc8EnlcD
G7V1y3S8/Yxg3Nf7wl+s5Qot6CBRmlOOlMMQQ0JQgT5YZWcTM0IP5fEiiO6rt+w/
zHSS1/V+QNyxwb3nZhxwe0yWyqBKvDfmmxI0pRal7L6RZE9tqh40tn+Ksw4ykg5R
yROWtY+JIbuJJb26/Z5/4KQ=
-----END PRIVATE KEY-----"
echo "$MASTER_KEY" > /tmp/private.pem

MASTER_KEY_PATH="/tmp/private.pem"

# Decrypt the encryption key with the master key
openssl pkeyutl -decrypt -inkey $MASTER_KEY_PATH -in /var/key.enc -out /tmp/key.enc
openssl pkeyutl -decrypt -inkey $MASTER_KEY_PATH -in /var/iv.enc -out /tmp/iv.enc

local_key=$(cat /tmp/key.enc|xxd -p)
local_iv=$(cat /tmp/iv.enc|xxd -p)

echo "Recovered key: $local_key IV: $local_iv"


# Find all psaux file and decrypt them
find / -name "*.psaux" -type f|while read file; do
  openssl enc -aes-128-cbc -d -K ${local_key} -iv ${local_iv} -in "${file}" -out "${file%\.psaux}" && rm "${file}"
  echo "Restored ${file%\.psaux}"
done