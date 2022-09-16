import React, { useState, memo } from "react";
import BottomNavItem from "../BottomNavItem";
import StyledBottomNav from "./styles";
import { Box } from "../Box";
import DropdownMenu from "../DropdownMenu/DropdownMenu";
import { BottomNavProps } from "./types";
import { NotificationDot } from "../NotificationDot";
import { Overlay } from "../Overlay";
import { useRouter } from "next/router";
import { NftIcon, SwapIcon, PaperIcon, WaterDropIcon } from "@pancakeswap/uikit";

const BottomNav: React.FC<React.PropsWithChildren<BottomNavProps>> = ({
  items = [],
  activeItem = "",
  activeSubItem = "",
  ...props
}) => {
  const [menuOpenByIndex, setMenuOpenByIndex] = useState({});
  const isBottomMenuOpen = Object.values(menuOpenByIndex).some((acc) => acc);
  const router = useRouter();

  return (
    <>
      {isBottomMenuOpen && <Overlay />}
      <StyledBottomNav justifyContent="space-around" {...props}>
        {/* {items.map(
          (
            { label, items: menuItems, href, icon, fillIcon, showOnMobile = true, showItemsOnMobile = true, disabled },
            index
          ) => {
            const statusColor = menuItems?.find((menuItem) => menuItem.status !== undefined)?.status?.color;
            return (
              showOnMobile && (
                <DropdownMenu
                  key={`${label}#${href}`}
                  items={menuItems}
                  isBottomNav
                  activeItem={activeSubItem}
                  showItemsOnMobile={showItemsOnMobile}
                  setMenuOpenByIndex={setMenuOpenByIndex}
                  index={index}
                  isDisabled={disabled}
                >
                  <Box>
                    <NotificationDot show={!!statusColor} color={statusColor}>
                      <BottomNavItem
                        href={href}
                        disabled={disabled}
                        isActive={href === activeItem}
                        label={label}
                        icon={icon}
                        fillIcon={fillIcon}
                        showItemsOnMobile={showItemsOnMobile}
                      />
                    </NotificationDot>
                  </Box>
                </DropdownMenu>
              )
            );
          }
        )} */}
        <BottomNavItem isActive={router.pathname === "/swap"} icon={SwapIcon} label="Swap" href="/swap">
          Swap
        </BottomNavItem>
        <BottomNavItem
          isActive={router.pathname === "/liquidity"}
          icon={WaterDropIcon}
          label="Liquidity"
          href="/liquidity"
        >
          Liquidity
        </BottomNavItem>
        <BottomNavItem label="NFT" icon={NftIcon} href="https://www.paytusker.com/">
          NFT
        </BottomNavItem>
        <BottomNavItem label="Whitepaper" icon={PaperIcon} href="/whitepaper-nft.pdf">
          Whitepaper
        </BottomNavItem>
      </StyledBottomNav>
    </>
  );
};

export default memo(BottomNav);
