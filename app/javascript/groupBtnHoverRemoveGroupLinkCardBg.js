export function groupBtnHoverRemoveGroupLinkCardBg() {
  const removeHoverBtns = document.querySelectorAll(".remove_hover_btn");
  const linkCards = document.querySelectorAll(".link_card");

  if (removeHoverBtns.length > 0) {
    removeHoverBtns.forEach(function(removeHoverBtn) {
      removeHoverBtn.addEventListener("mouseover", function() {
        linkCards.forEach(function(linkCard) {
          linkCard.classList.remove("group-hover:bg-base-300/30");
        });
      });

      removeHoverBtn.addEventListener("mouseout", function() {
        linkCards.forEach(function(linkCard) {
          linkCard.classList.add("group-hover:bg-base-300/30");
        });
      });
    });
  }
}
