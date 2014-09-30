# Actions for CTFCorrection package

## Tiff2Mrc

```
tiff2mrc -i {$I[1]} -o {$O[1]}.mrc -r {$RESOLUTION} -m {$TIFF2MRC_m} -Offset {$TIFF2MRC_Offset}
```

## Mrc2Cen

```
mrcImageCenterGet -i {$I[1]} -o {$O[1]} -Nx {$MRC_IMAGE_CENTER_Nx} -Ny {$MRC_IMAGE_CENTER_Ny}
```

## Cen2Nor

```
mrcImageAbnormalValueRemove -i {$I[1]} -o {$O[1]} -u {$MRC_IMAGE_ABNORMAL_VALUE_REMOVE_u_MAX} {$MRC_IMAGE_ABNORMAL_VALUE_REMOVE_u_HALF} -m {$MRC_IMAGE_ABNORMAL_VALUE_REMOVE_m}
```

## Nor2Fft

```
mrcImageFFT -i {$I[1]} -o {$O[1]}
```

## Fft2Ctfinfo

```
ctfDetermine -i {$I[1]} -o {$O[1]} -D {$MRC_DETERMINE_D} -m {$MRC_DETERMINE_m} -CutLow {$MRC_DETERMINE_CutLow} -CutHigh {$MRC_DETERMINE_CutHigh} -d {$MRC_DETERMINE_d} -Cc {$CTF_DETERMINE_Cc} -Cs {$CTF_DETERMINE_Cs}
```

## Ctfinfo2Ctf

### inputs

1. input '*.fft'
2. input '{$*}.ctfinfo'

### action

```
mv {$I[2]} {$I[2]}.tmp2
grep .: {$I[2]}.tmp2 > {$I[2]}
mrcImageCTFCompensation -i {$I[1]} -info2 {$I[2]} -o {$O[1]} -m {$MRC_IMAGE_CTF_COMPENSATION_m}
```
