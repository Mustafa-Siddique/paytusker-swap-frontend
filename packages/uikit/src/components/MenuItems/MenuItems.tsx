/* eslint-disable @typescript-eslint/no-explicit-any */
import { createElement, memo } from "react";
import { Flex } from "../Box";
import isTouchDevice from "../../util/isTouchDevice";
import DropdownMenu from "../DropdownMenu/DropdownMenu";
import MenuItem from "../MenuItem/MenuItem";
import { MenuItemsProps } from "./types";

const MenuItems: React.FC<React.PropsWithChildren<MenuItemsProps>> = ({
  items = [],
  activeItem,
  activeSubItem,
  ...props
}) => {
  return (
    <Flex {...props}>
      {/* {items.map(({ label, items: menuItems = [], href, icon, disabled }) => {
        const statusColor = menuItems?.find((menuItem) => menuItem.status !== undefined)?.status?.color;
        const isActive = activeItem === href;
        const linkProps = isTouchDevice() && menuItems && menuItems.length > 0 ? {} : { href };
        const Icon = icon;
        return (
          <DropdownMenu
            key={`${label}#${href}`}
            items={menuItems}
            py={1}
            activeItem={activeSubItem}
            isDisabled={disabled}
          >
            <MenuItem {...linkProps} isActive={isActive} statusColor={statusColor} isDisabled={disabled}>
              {label || (icon && createElement(Icon as any, { color: isActive ? "secondary" : "textSubtle" }))}
            </MenuItem>
            </DropdownMenu>
            );
          })} */}
      <MenuItem href="/swap">Swap</MenuItem>
      <MenuItem href="/liquidity">Liquidity</MenuItem>
      <MenuItem>
        <a href="https://www.paytusker.com/" target="_blank">
          NFT
        </a>
      </MenuItem>
      <MenuItem>
        <a href="/whitepaper-nft.pdf" target="_blank">
          Whitepaper
        </a>
      </MenuItem>
    </Flex>
  );
};

export default memo(MenuItems);
