import { Controller } from "@hotwired/stimulus"

// 使い方ページの目次機能を制御するStimulusコントローラー
export default class extends Controller {
  static targets = ["section", "navLink"]

  connect() {
    // バインドした関数を保存してdisconnectで正しく削除できるようにする
    this.boundHandleSmoothScroll = this.handleSmoothScroll.bind(this)
    this.boundUpdateActiveNavigation = this.updateActiveNavigation.bind(this)
    
    this.initializeSmoothScroll()
    this.initializeActiveNavigation()
  }

  // スムーズスクロール機能を初期化
  initializeSmoothScroll() {
    this.navLinkTargets.forEach(link => {
      link.addEventListener('click', this.boundHandleSmoothScroll)
    })
  }

  // アクティブナビゲーション機能を初期化
  initializeActiveNavigation() {
    window.addEventListener('scroll', this.boundUpdateActiveNavigation)
  }

  // スムーズスクロールのハンドラー
  handleSmoothScroll(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const targetId = event.currentTarget.getAttribute('href')
    const targetElement = document.querySelector(targetId)
    
    // モバイルドロワーを閉じる
    const isMobileDrawer = event.currentTarget.getAttribute('data-mobile-drawer') === 'true'
    if (isMobileDrawer) {
      const mobileDrawer = document.getElementById('mobile-drawer')
      if (mobileDrawer) {
        mobileDrawer.checked = false
      }
    }
    
    if (targetElement) {
      targetElement.scrollIntoView({
        behavior: 'smooth',
        block: 'start'
      })
    }
  }

  // アクティブナビゲーションの更新
  updateActiveNavigation() {
    let currentSection = ''
    
    // 現在表示されているセクションを特定
    const sectionsToCheck = this.sectionTargets.length > 0 ? this.sectionTargets : document.querySelectorAll('[data-how-to-use-target="section"]')
    
    sectionsToCheck.forEach(section => {
      const sectionTop = section.offsetTop - 300
      if (window.scrollY >= sectionTop) {
        currentSection = section.getAttribute('id')
      }
    })

    // ナビゲーションリンクのアクティブ状態を更新
    const linksToUpdate = this.navLinkTargets.length > 0 ? this.navLinkTargets : document.querySelectorAll('[data-how-to-use-target="navLink"]')
    
    linksToUpdate.forEach(link => {
      link.classList.remove('bg-primary/20')
      if (link.getAttribute('href') === `#${currentSection}`) {
        link.classList.add('bg-primary/20')
      }
    })
  }

  disconnect() {
    // クリーンアップ
    if (this.boundHandleSmoothScroll) {
      this.navLinkTargets.forEach(link => {
        link.removeEventListener('click', this.boundHandleSmoothScroll)
      })
    }
    
    if (this.boundUpdateActiveNavigation) {
      window.removeEventListener('scroll', this.boundUpdateActiveNavigation)
    }
  }
}
