#
# Eos for 3D reconstrucion from 2D rois using 3D initail reference 
#

.SUFFIXES: .3d .ref3d .ref2d .pad .padtmp .mask .maskfit .fit .fitmask .roi .corinfo .3dinfo .3dlst .3d .3dsm .3dsmCenter .ds6 .3dsmds6 .corinfo2 .corinfolst .cormap .parcorinfolst .parcorinfolstsort .gnuplotcorinfolst .3dlstselect .monlst .mon

SHELL=/bin/bash

-include ROIs
-include CORINFOs
-include PADs
-include 3DINFOs
-include 3DLIST
-include CORINFO2s

#
# Initial Reference Model 
INITIAL=initial
# Target structure name 
TARGET=all

# Simultaneous Jobs for AutoRotaionCorrelation
JOP_NUM=-j 3

#
# Search Area for 3D
#
ROTMODE=YOYS
# Rot1
ROT1MIN=0
ROT1MAX=359
ROT1D=30
nRot1=12
#
ROT2MIN=0
ROT2MAX=359
ROT2D=30
nRot2=12
# Rot3
ROT3MIN=0
ROT3MAX=0
ROT3D=30
nRot3=1
# For 2D 
STEP=12
ROTMIN=0
ROTMAX=359
nROT=`echo "" | awk 'BEGIN {printf 360 / $(STEP)}'`

# Seletion Step 
COR_THRESHOLD=0.4
Y_SHIFT_THRESHOLD=20

# Pad size for 2D 
PAD_W=64
PAD_H=64

###
### Initial model from PDB
###
REFSOURCE=121p-shift
DELTA=2.5
SIZE_X=64
SIZE_Y=64
SIZE_Z=64
START_X=`awk 'BEGIN { print -1*$(DELTA)*$(SIZE_X)/2}'`
START_Y=`awk 'BEGIN { print -1*$(DELTA)*$(SIZE_Y)/2}'`
START_Z=`awk 'BEGIN { print -1*$(DELTA)*$(SIZE_Z)/2}'`
SNRATIO=3
###############################

Help::
	@echo "----- Makefile for Single Particle with Reference"
	@echo "1. Prepare files from EM images, which has a suffix of roi "
	@echo "2. Prepare an initial model as $(INITIAL).3d "
	@echo "3. make First"
	@echo "4. make All"
	@echo "If you want to repeat refinement again, "
	@echo "  1. make Again"
	@echo "  2. make All"
	@echo ""
	@echo "--- If you want to create an initail model from PDB ---"
	@echo " make InitialModel"
	@echo ""
	@echo "--- If you want to create an test from the initial model ---"
	@echo " make TestData"

pad:$(ROIs:.roi=.pad)
corinfo:$(PADs:.pad=.corinfo)
3dinfo:$(CORINFOs:.corinfo=.3dinfo)
fit:$(ROIs:.roi=.fit)
3dlst:$(3DINFOs:.3dinfo=.3dlst)
3d:$(3DLIST:.3dlst=.3d)
corinfo2:$(CORINFOs:.corinfo=.corinfo2)
parcorinfolst:$(CORINFO2s:.corinfo2=.parcorinfolst)

#
#
#
InitialModel::
	pdb2mrc -i $(REFSOURCE).pdb -o $(INITIAL).3d -nx $(SIZE_X) -ny $(SIZE_Y) -nz $(SIZE_Z) -Sx $(START_X) -Sy $(START_Y) -Sz $(START_Z) -dx $(DELTA) -dy $(DELTA) -dz $(DELTA) -m 1

TestData::
	@for (( rot1 = $(ROT1MIN); rot1 <= $(ROT1MAX); rot1 += $(ROT1D)*2 )) \
	do \
	for (( rot2 = $(ROT2MIN); rot2 <= $(ROT2MAX); rot2 += $(ROT2D)*2 )) \
	do \
	for (( rot3 = $(ROT3MIN); rot3 <= $(ROT3MAX); rot3 += $(ROT3D)*2 )) \
	do \
		echo $$rot1, $$rot2, $$rot3; \
		mrc3Dto2D -i $(INITIAL).3d -o $(REFSOURCE)-$$rot1-$$rot2-$$rot3.roi \
				  -InterpolationMode 2 -EulerMode $(ROTMODE) \
				  -Rot1 $$rot1 $$rot1 1 \
				  -Rot2 $$rot2 $$rot2 1 \
				  -Rot3 $$rot3 $$rot3 1 ; \
	done \
	done \
	done

TestDataNoise::
	@for (( rot1 = $(ROT1MIN); rot1 <= $(ROT1MAX); rot1 += $(ROT1D)*2 )) \
	do \
	for (( rot2 = $(ROT2MIN); rot2 <= $(ROT2MAX); rot2 += $(ROT2D)*2 )) \
	do \
	for (( rot3 = $(ROT3MIN); rot3 <= $(ROT3MAX); rot3 += $(ROT3D)*2 )) \
	do \
		echo $$rot1, $$rot2, $$rot3; \
		name="$(REFSOURCE)-noise-$$rot1-$$rot2-$$rot3.roi"; \
		mrc3Dto2D -i $(INITIAL).3d -o $$name.noNoise \
				  -InterpolationMode 2 -EulerMode $(ROTMODE) \
				  -Rot1 $$rot1 $$rot1 1 \
				  -Rot2 $$rot2 $$rot2 1 \
				  -Rot3 $$rot3 $$rot3 1 ; \
		mrcImageNoiseAdd -i $$name.noNoise -o $$name -SN $(SNRATIO) ; \
		rm $$name.noNoise ; \
	done \
	done \
	done

##############
ROIs::
	touch ROIs
	echo "ROIs=\\" > ROIs
	find -name "*.roi" -type f | sed s/..// | xargs ls -1 | sed s/roi/roi\\\\/ >> ROIs
	echo "" >> ROIs

CORINFOs::
	touch CORINFOs
	echo "CORINFOs=\\" > CORINFOs
	find -name "*.corinfo" -type f | sed s/..// | xargs ls -1 | sed s/corinfo/corinfo\\\\/ >> CORINFOs
	echo "" >> CORINFOs

PADs::
	touch PADs
	echo "PADs=\\" > PADs
	find -name "*.pad" -type f | sed s/..// | xargs ls -1 | sed s/pad/pad\\\\/ >> PADs
	echo "" >> PADs

3DINFOs::
	touch 3DINFOs
	echo "3DINFOs=\\" > 3DINFOs
	find -name "*.3dinfo" -type f | sed s/..// | xargs ls -1 | sed s/3dinfo/3dinfo\\\\/ >> 3DINFOs
	echo "" >> 3DINFOs

3DLIST::
	touch 3DLIST
	echo "3DLIST=\\" > 3DLIST
	find -name "*.3dlst" -type f | sed s/..// | xargs ls -1 | sed s/3dlst/3dlst\\\\/ >> 3DLIST
	echo "" >> 3DLIST

CORINFO2s::
	touch CORINFO2s
	echo "CORINFO2s=\\" > CORINFO2s
	find -name "*.corinfo2" -type f | sed s/..// | xargs ls -1 | sed s/corinfo2/corinfo2\\\\/ >> CORINFO2s
	echo "" >> CORINFO2s

##############
First::
	cp $(INITIAL).3d $(TARGET).ref3d
	touch *.roi

All::
	make $(TARGET).ref2d;
	make ROIs;
	make $(JOP_NUM) pad;
	make PADs;
	make $(JOP_NUM) corinfo;
	make CORINFOs;
	make $(JOP_NUM) 3dinfo;
	make 3DINFOs;
	make $(JOP_NUM) 3dlst;
	make 3DLIST;
	make $(TARGET).3d;

Again::
	touch *.pad
	cp $(TARGET).3d $(TARGET).ref3d;
	TMPNAME=`date +%y%m%d%H%M%S`;	\
	mv $(TARGET).3dlst   $(TARGET).3dlst.$$TMPNAME;	\
	mv $(TARGET).3d      $(TARGET).3d.$$TMPNAME;	\
	mv $(TARGET).3dsm    $(TARGET).3dsm.$$TMPNAME;	\
	mv $(TARGET).ds6     $(TARGET).ds6.$$TMPNAME;	\
	mv $(TARGET).3dsmds6 $(TARGET).3dsmds6.$$TMPNAME;	
	

#### Prepare Reference ####

.ref3d.ref2d:
	mrc3Dto2D -i $(TARGET).ref3d -o $(TARGET).ref2d -EulerMode $(ROTMODE) -InterpolationMode 2 -Rot2 $(ROT2MIN) $(ROT2MAX) $(ROT2D) -Rot1 $(ROT1MIN) $(ROT1MAX) $(ROT1D) -Rot3 $(ROT3MIN) $(ROT3MAX) $(ROT3D) -m 0

.roi.pad:
	mrcImageWindowing -i $*.roi -o $*.mask -W 0.1 0.0 0.05 0.0 -m 18
	mrcImagePad -i $*.mask -o $*.padtmp -W $(PAD_W) -H $(PAD_H) -m 3
	mrcImageWindowing -i $*.padtmp -o $*.pad -W 0.1 0.0 0.1 0.0 -m 2 

.pad.corinfo:
	mrcImageAutoRotationCorrelation -i $*.pad -r $(TARGET).ref2d -O $*.corinfo -fit $*.fit -cor $*.cormap -n $(nRot) -m 18 -range $(ROTMIN) $(ROTMAX) -Iter 2 -nRot2 $(nRot2) -nRot1 $(nRot1) -nRot3 $(nRot3) 2> /dev/null

##############################################################################


.corinfo.3dinfo:
	awk '/Cor/ { print $$7,$$16,$$2,$$3,$$4,$$5,$$9,$$11,$$12}' $*.corinfo | sort -r | sed -e s/.pad/.fit/ > $*.3dinfolst
	head -n 1 $*.3dinfolst | awk '{print $$2,$$3,$$4,$$5,$$6,$$1}' > $*.3dinfo
##   ##18 -> ##7  ##

.3dinfo.3dlst:
	cat $*.3dinfo >> $(TARGET).3dlst		
	
.3dlst.3d:
	mrc2Dto3D -I $(TARGET).3dlst -o $(TARGET).3d -InterpolationMode 2 -Double -DoubleCounter $(TARGET).3dcounter -CounterThreshold 0.5 -m 1 -WeightMode 2

.3d.3dsm:
	mrcImageSmoothing -i $(TARGET).3d -o $(TARGET).3dsm -m 1 -M 1 -r 3

.3dsm.3dsmCenter:
	mrcImageCenterGet -i $(TARGET).3dsm -o $(TARGET).3dsmCenter -Nx 128 -Ny 128 -Nz 128

.3dsmCenter.ds6:
	mrc2map -i $(TARGET).3dsmCenter -o $(TARGET).ds6 -m 3

.3d.ds6:
	mrc2map -i $*.3d -o $*.ds6 -m 0 

#####Select Particles#####

.corinfo.corinfo2:
	awk '/Cor/ { print $$18,$$16,$$2,$$3,$$4,$$5,$$9,$$11,$$12}' $*.corinfo | sort -r | sed -e 's/.roi/.fit/' > $*.corinfolst
	head -n 1 $*.corinfolst | awk '{if($(PAD_W)-$$8>=$$8&&$(PAD_H)-$$9>=$$9) print $$1,$$2,$$3,$$4,$$5,$$6,$$7,0+$$8,0+$$9;else if($(PAD_W)-$$8>=$$8) print $$1,$$2,$$3,$$4,$$5,$$6,$$7,0+$$8,$(PAD_H)-$$9;else if($(PAD_H)-$$9>=$$9) print $$1,$$2,$$3,$$4,$$5,$$6,$$7,$(PAD_W)-$$8,0+$$9;else print $$1,$$2,$$3,$$4,$$5,$$6,$$7,$(PAD_W)-$$8,$(PAD_H)-$$9}' > $*.corinfo2

.corinfo2.parcorinfolst:
	cat $*.corinfo2 >> $(TARGET).parcorinfolst

CorinfoSort::
	awk '{ print $$1,$$2,$$3,$$4,$$5,$$6,$$7,$$8,$$9}' $(TARGET).parcorinfolst | sort -r > $(TARGET).parcorinfolstsort

SelectParticle::
	awk '$$1 >= $(COR_THRESHOLD) || $$9 <= $(Y_SHIFT_THRESHOLD){print $$2,$$3,$$4,$$5,$$6,$$1}' $(TARGET).parcorinfolstsort > $(TARGET).3dlstselect


#####Check alignment#####

GnuplotCorinfo::
	awk '{ print $$1,$$9}' $(TARGET).parcorinfolst | sort -r > $(TARGET).gnuplotcorinfolst
####################################################
	##gnuplot 
	##set out "Corinfo.ps" 
	##plot "$(TARGET).gnuplotcorinfolst"
###################################################

GnuplotAngle::
	awk '{ print $$4,$$5}' $(TARGET).parcorinfolst > $(TARGET).gnuplotanglelst
######################################################
	##gnuplot
	##set out "Angle.ps"
	##plot "$(TARGET).gnuplotanglelst"
######################################################	

GnuplotShift::
	awk '{ print $$4,$$5}' $(TARGET).parcorinfolst > $(TARGET).gnuplotshiftlst
######################################################
	##gnuplot
	##set out "Shift.ps"
	##plot "$(TARGET).gnuplotshiftlst"
######################################################  

MontageList::
	awk '{ print $$1}' $(TARGET).3dlst > $(TARGET).monlst
	mrcImageMontageCreate -i $(TARGET).monlst -o $(TARGET).mon -nx 15 -ny 10
