export function bgStarShow() {
// ランダムな box-shadow の文字列を生成する関数
function generateBoxShadows(count) {
  const shadows = [];
  for (let i = 0; i < count; i++) {
    const x = Math.floor(Math.random() * 2000);
    const y = Math.floor(Math.random() * 6000);
    // 白い星を生成
    shadows.push(`${x}px ${y}px rgba(255, 255, 255, 50%)`);
  }
  return shadows.join(', ');
}

// 各星要素に対するランダムな box-shadow を生成
const star1Shadows = generateBoxShadows(1500);
const star2Shadows = generateBoxShadows(300);
const star3Shadows = generateBoxShadows(150);

// 要素取得
const stars1 = document.getElementById('stars1');
const stars2 = document.getElementById('stars2');
const stars3 = document.getElementById('stars3');

// 生成した box-shadow を直接 style に設定
stars1.style.boxShadow = star1Shadows;
stars2.style.boxShadow = star2Shadows;
stars3.style.boxShadow = star3Shadows;

// 疑似要素にはインラインスタイルが使えないため、動的にスタイルシートへ追加
const styleTag = document.createElement('style');
styleTag.textContent = `
#stars1::before { box-shadow: ${star1Shadows}; }
#stars2::before { box-shadow: ${star2Shadows}; }
#stars2::after { box-shadow: ${star2Shadows}; }
#stars3::before { box-shadow: ${star3Shadows}; }
#stars3::after { box-shadow: ${star3Shadows}; }
`;
document.head.appendChild(styleTag);
}
