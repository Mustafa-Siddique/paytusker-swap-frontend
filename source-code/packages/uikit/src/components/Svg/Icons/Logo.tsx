import React from "react";
import Svg from "../Svg";
import { SvgProps } from "../types";

const Icon: React.FC<React.PropsWithChildren<SvgProps>> = (props) => {
  return (
    <Svg viewBox="0 0 198 199" {...props}>
      <defs>
        <style>{`
          .cls-1 {
            fill: url(#linear-gradient);
          }
        `}</style>
        <linearGradient
          id="linear-gradient"
          x1="379.54"
          y1="547"
          x2="4825.03"
          y2="547"
          gradientTransform="translate(-282 -5)"
          gradientUnits="userSpaceOnUse"
        >
          <stop offset="0" stop-color="#fc1481" />
          <stop offset="1" stop-color="#4d3591" />
        </linearGradient>
      </defs>
      <path
        // className="cls-1"
        style={{ fill: "url(#linear-gradient)" }}
        d="M540.54,99c-244.66,0-443,198.34-443,443,0,175.9,102.53,327.84,251,399.36A889.22,889.22,0,0,0,526.41,697.52c77.36-156.51,90.67-300.2,91.82-382.44a1.17,1.17,0,0,1,2.31-.28c19.58,75.59,49.53,236.55-4.59,427.49A813.94,813.94,0,0,1,502.11,983.35q19,1.62,38.43,1.65c244.67,0,443-198.34,443-443S785.21,99,540.54,99Zm165,520.76c-1.2-1.2,3.54-6.1,6.53-9.75,37.77-46.26,61.17-207.2-20.67-277.73C617.41,268.57,494,310.06,476.92,315.79c-136.83,46-247.63,149.79-271,178.85a1.17,1.17,0,0,1-1.93-1.32c39.64-69,129.16-197.61,291.79-262.36,111.13-44.26,321.72-61.34,391.16,49.48,47.58,75.95,6.27,176.94,2.36,186.16C841.2,579.7,710.2,624.47,705.49,619.76Z"
      />
    </Svg>
  );
};

export default Icon;
