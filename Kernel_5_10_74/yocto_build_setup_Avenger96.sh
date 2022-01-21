#!/bin/bash


#----------------------------------------------------------------------------------------------------------------
#  Yocto setup build script
#----------------------------------------------------------------------------------------------------------------
#  The script will create Yocto environment which is require to build the system.
#
#----------------------------------------------------------------------------------------------------------------

YOCTO_DIR="$(pwd)"
SOURCE_DIR="$(pwd)/dhcom-yocto-bsp/sources"
SD_CARD_IMG="$(pwd)/dhcom-yocto-bsp/build/tmp/deploy/images/dh-stm32mp1-dhcor-avenger96/dh-image-demo-dh-stm32mp1-dhcor-avenger96.wic.xz"
red=`tput setaf 1`
green=`tput setaf 2`
bold=`tput bold`
reset=`tput sgr0`

#following commit head is checkedout for the repos before applying patches 
meta_poky_head=0839888394a6e42e96f9f0d201376eb38bc79b24
meta_dhsom_extras_head=47fef5536eb0dc2c806fe416d6fe5ff7ccae7126
meta_dhsom_stm32_bsp_head=7dc64e45d69ec15e3f71246c99da0595ea29a7fa
meta_dhsom_stm32_common_head=49bb5d15e6294ac24fe362713e2145535e11976b
meta_mainline_common_head=985fbd430da9219ae4524060fae3f40909f44713
meta_mainline_graphics_head=5cdafcd9929e9b1534063efe3bff1a98b8df84ab
meta_openembedded_head=7889158dcd187546fc5e99fd81d0779cad3e8d17
meta_python2_head=b901080cf57d9a7f5476ab4d96e56c30db8170a8
meta_qt5_head=b4d24d70aca75791902df5cd59a4f4a54aa4a125
meta_swupdate_head=9659220cee3964322ae387f04e47bb3674b37f7c

# Required packages to build
# Install all the required build HOST packages
prerequisite()
{
	echo "###################################################################################"
	echo "Checking for required host packages and if not installed then install it..."
	echo "###################################################################################"

	sudo apt-get install repo gcc g++ gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat cpio python python3 libsdl1.2-dev xterm sed cvs subversion coreutils texi2html docbook-utils python3-pip python3-pexpect python3-jinja2 python3-git python-pip python-pysqlite2 xz-utils debianutils iputils-ping help2man make desktop-file-utils libgl1-mesa-dev libglu1-mesa-dev mercurial autoconf automake groff curl lzop asciidoc u-boot-tools libegl1-mesa pylint3 -y

	if [ $? -ne 0 ]
	then
		echo "[ERROR] : Failed to get required HOST packages. Please correct error and try again."
		exit -1
	fi

	git lfs > /dev/null
	if [ $? -ne 0 ]
	then
		curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
		sudo apt-get install git-lfs -y
		git lfs install
	fi
	echo "###################################################################################"
	echo "Required HOST packages successfully installed."
	echo "###################################################################################"
}


# To get the BSP you need to have `repo` installed.
# Install the `repo` utility. (only need to do this once)
create_repo()
{
	# create ~/bin if not there
	mkdir -p ~/bin

	echo "###################################################################################"
	echo "Creating repo..."
	echo "###################################################################################"
	curl https://storage.googleapis.com/git-repo-downloads/repo  > ~/bin/repo

	sudo chmod a+x ~/bin/repo
	export PATH=~/bin:$PATH
}


# Download the Yocto Project Environment into your directory
download_dhcom_repo()
{
	echo "###################################################################################"
	echo "Creating yocto setup..."
	echo "###################################################################################"
	mkdir $YOCTO_DIR/dhcom-yocto-bsp
	cd $YOCTO_DIR/dhcom-yocto-bsp
	if [ -d .repo ];
	then
		echo "Yocto dhcom repo is already setup. No need to do anything."
	else
		echo "###################################################################################"
		echo "Download the yocto repo"
		echo "###################################################################################"
		repo init -u https://github.com/dh-electronics/dhcom_stm32mp1-bsp-platform -b dunfell 
		echo "###################################################################################"
		echo "Sync downloaded repo. Please wait..."
		echo "###################################################################################"
		repo sync
		if [ $? -eq 0 ]; 
		then
			echo "repo sync sucessfull..."
		else
			echo "${red}Error in repo sync. Please correct the error manually and try again.${reset}"
			sudo rm -r .repo
			exit -1
		fi
	fi
}

# Apply patches
apply_patch()
{	
	#Checkout all the repos with commit head 
	cd $SOURCE_DIR/poky/
	git checkout -f $meta_poky_head

	cd $SOURCE_DIR/meta-dhsom-extras/
    git checkout -f $meta_dhsom_extras_head

	cd $SOURCE_DIR/meta-dhsom-stm32-bsp/
    git checkout -f $meta_dhsom_stm32_bsp_head

	cd $SOURCE_DIR/meta-dhsom-extras/
    git checkout -f $meta_dhsom_extras_head

	cd $SOURCE_DIR/meta-dhsom-stm32-common/
    git checkout -f $meta_dhsom_stm32_common_head

	cd $SOURCE_DIR/meta-mainline-common/
    git checkout -f $meta_mainline_common_head

	cd $SOURCE_DIR/meta-mainline-graphics/
    git checkout -f $meta_mainline_graphics_head

	cd $SOURCE_DIR/meta-openembedded/
    git checkout -f $meta_openembedded_head

	cd $SOURCE_DIR/meta-python2/
    git checkout -f $meta_python2_head

	cd $SOURCE_DIR/meta-qt5/
    git checkout -f $meta_qt5_head

	cd $SOURCE_DIR/meta-swupdate/
    git checkout -f $meta_swupdate_head

	# Apply patch 1
	cd $SOURCE_DIR
	
	if [ ! -d meta-einfochips-ap1302 ]
	then
		cp -r $YOCTO_DIR/Avenger96_L5_10_74_Rel_1_0_patches/meta-einfochips-ap1302/ .
		if [ $? -ne 0 ]
		then
			echo "###################################################################################"
			echo "${red}Error during apply the patch in meta-einfochips-ap1302"
			echo "Please verify Avenger96_L5_10_74_Rel_1_0_patches directory${reset}"
			echo "###################################################################################"
			exit 1
		fi
	fi

	# Apply patche 2
	cd $SOURCE_DIR/meta-dhsom-stm32-common/
	git apply --check -R $YOCTO_DIR/Avenger96_L5_10_74_Rel_1_0_patches/meta-dhsom-stm32-common-patches/00* 2>/dev/null
	if [ $? -ne 0 ]
	then
		echo "###################################################################################"
		echo "Apply the patch in meta-dhsom-stm32-common"
		echo "###################################################################################"
		git checkout -f $meta_dhsom_stm32_common_head
		git am --whitespace=fix $YOCTO_DIR/Avenger96_L5_10_74_Rel_1_0_patches/meta-dhsom-stm32-common-patches/00*
		if [ $? -ne 0 ]
		then
			echo "###################################################################################"
			echo "${red}Error during apply the patch in meta-dhsom-stm32-common"
			echo "Please verify Avenger96_L5_10_74_Rel_1_0_patches directory${reset}"
			echo "###################################################################################"
			git format-patch $meta_dhsom_stm32_common_head
			exit 1
		fi
	fi

	#Apply patch 3
	cd $SOURCE_DIR/meta-dhsom-stm32-bsp/
	git apply --check -R $YOCTO_DIR/Avenger96_L5_10_74_Rel_1_0_patches/meta-dhsom-stm32-bsp-patches/00* 2>/dev/null
	if [ $? -ne 0 ]
	then
		echo "###################################################################################"
		echo "Apply the patch in meta-dhsom-stm32-common"
		echo "###################################################################################"
		git checkout -f $meta_dhsom_stm32_bsp_head
		git am --whitespace=fix $YOCTO_DIR/Avenger96_L5_10_74_Rel_1_0_patches/meta-dhsom-stm32-bsp-patches/00*
		if [ $? -ne 0 ]
		then
			echo "###################################################################################"
			echo "${red}Error during apply the patch in meta-dhsom-stm32-bsp"
			echo "Please verify Avenger96_L5_10_74_Rel_1_0_patches directory${reset}"
			echo "###################################################################################"
			git format-patch $meta_dhsom_stm32_bsp_head
			exit 1
		fi
	fi

	echo "#####################################Apply patch done########################################"
}

# Build an image
build_image()
{
	cd $YOCTO_DIR/dhcom-yocto-bsp/

	# Run Yocto setup
	# [MACHINE=<machine>] [DISTRO=<available_distribution>] source ./setup-environment <build_dir>
	MACHINE=dh-stm32mp1-dhcor-avenger96 DISTRO=dhlinux source ./setup-environment build	
	echo "${green}###################################################################################"
	echo "Starting SD card image build now. If the image is build first time then It will take a long time (approx 7 to 8 hrs) to finish."
	echo "***Build time may vary base on your HOST PC configurations"
	echo "***Build log show on console"
	echo "###################################################################################${reset}"
	bitbake dh-image-demo
	if [ $? -ne 0 ];then
		echo "${red}[ERROR] : Error in building the image. Please see the error log for resolution.${reset}"
		bitbake dh-image-demo -c cleansstate
		exit 1
	else
		echo "${green}${bold}###################################################################################"
		echo "SD card image build successfully"
		echo "You can find dh-image-demo-dh-stm32mp1-dhcor-avenger96.wic.xz image at below location"
		echo "$(pwd)/tmp/deploy/images/dh-stm32mp1-dhcor-avenger96/"
		echo "###################################################################################${reset}"
	fi
}

#--------------------------
# Main execution starts here
#---------------------------

echo "${green}${bold}########### Yocto setup script used to setup environment automatically ############"
echo "NOTE:: It's one time setup script if you want to change and build any package(i.e kernel,uboot...) after the setup"
echo "       Please do this manually by refering the board user guide"
echo "###################################################################################${reset}"
sleep 5
if [ -f "$SD_CARD_IMG" ]
then
	echo "${green}#####################################################################################################"
	echo "SD card image dh-image-demo-dh-stm32mp1-dhcor-avenger96.wic.xz exists. Your yocto setup is already up to date"
	echo "#####################################################################################################${reset}"
else
	# Check prerequisite
	prerequisite

	# create repo
	create_repo
	sync

	# Setup Yocto environment
	download_dhcom_repo
	sync

	# Apply patches
	apply_patch

	# Build an image
	build_image

	echo "${green}${bold}########## Build script ended successfully ##########${reset}"
fi

