#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Archipelago connects over TLS with OpenSSL, which cannot read the iOS trust store. Its client looks for
// <app directory>/networking/cacert.pem (Documents on iOS): install the CA list bundled with the app there.
void MaskPad_InstallArchipelagoCertificates(void);

#ifdef __cplusplus
}
#endif
