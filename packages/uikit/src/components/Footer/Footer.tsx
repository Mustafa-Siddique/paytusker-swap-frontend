import React from "react";
import { Box, Flex } from "../Box";
import {
  StyledFooter,
  StyledIconMobileContainer,
  StyledSocialLinks,
  StyledToolsContainer,
} from "./styles";

// import CakePrice from "../CakePrice/CakePrice";
import { LogoWithTextIcon } from "../Svg";
import { FooterProps } from "./types";

const MenuItem: React.FC<React.PropsWithChildren<FooterProps>> = ({
  isDark,
  ...props
}) => {
  return (
    <StyledFooter
      data-theme={isDark ? "dark" : "light"}
      p={["40px 16px", null, "56px 40px 32px 40px"]}
      {...props}
      justifyContent="center"
    >
      <Flex flexDirection="column" width={["100%", null, "1200px;"]}>
        <StyledIconMobileContainer display={["block", null, "none"]}>
          <LogoWithTextIcon isDark width="130px" />
        </StyledIconMobileContainer>
        <Flex
          order={[2, null, 1]}
          flexDirection={["column", null, "row"]}
          justifyContent="center"
          alignItems="center"
          mb={["42px", null, "36px"]}
        >
          {/* {items?.map((item) => (
            <StyledList key={item.label}>
              <StyledListItem>{item.label}</StyledListItem>
              {item.items?.map(({ label, href, isHighlighted = false }) => (
                <StyledListItem key={label}>
                  {href ? (
                    <Link
                      data-theme="dark"
                      href={href}
                      target="_blank"
                      rel="noreferrer noopener"
                      color={isHighlighted ? vars.colors.warning : "text"}
                      bold={false}
                    >
                      {label}
                    </Link>
                  ) : (
                    <StyledText>{label}</StyledText>
                  )}
                </StyledListItem>
              ))}
            </StyledList>
          ))} */}
          <Box display={["block", null, "block"]}>
            {/* <LogoWithTextIcon isDark width="160px" /> */}
            <img src="/images/aytusker-with-text.svg" width="100%" className="desktop-icon" alt="" />
          </Box>
        </Flex>
        <StyledSocialLinks
          order={[2]}
          pt={["42px", null, "32px"]}
          mb={["32px", null, "32px"]}
          mt={["0", null, "32px"]}
        />

        <StyledToolsContainer
          data-theme="dark"
          order={[3, null, 3]}
          flexDirection={["column", null, "row"]}
          justifyContent="space-between"
          style={{ border: "none", marginBottom: 0 }}
        >
          <Flex order={[1, null, 1]} alignItems="center" style={{ color: isDark ? "white" : "black" }}>
            © 2022 Paytusker. All Rights Reserved.
          </Flex>

          {/* <Flex order={[1, null, 2]} mb={["24px", null, "0"]} justifyContent="space-between" alignItems="center">
            <Box mr="20px">
              <CakePrice cakePriceUsd={cakePriceUsd} color="textSubtle" />
            </Box>
            <Button
              data-theme="light"
              as="a"
              href="https://pancakeswap.finance/swap?outputCurrency=0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82&chainId=56"
              target="_blank"
              scale="sm"
              endIcon={<ArrowForwardIcon color="backgroundAlt" />}
            >
              {buyCakeLabel}
            </Button>
          </Flex> */}
        </StyledToolsContainer>
      </Flex>
    </StyledFooter>
  );
};

export default MenuItem;
