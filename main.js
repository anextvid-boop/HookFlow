import './style.css'

document.addEventListener('DOMContentLoaded', () => {
  const form = document.querySelector('#waitlist-form')
  const formMessage = document.querySelector('#form-message')
  const emailInput = document.querySelector('#email')
  const submitButton = document.querySelector('.input-group button')

  if (form) {
    form.addEventListener('submit', (e) => {
      e.preventDefault()
      
      const email = emailInput.value
      
      if (email) {
        // Simulate an API call
        submitButton.textContent = 'Joining...'
        submitButton.disabled = true
        
        setTimeout(() => {
          formMessage.classList.remove('hidden')
          emailInput.value = ''
          submitButton.textContent = 'Join Waitlist'
          submitButton.disabled = false
          
          // Clear message after 5 seconds
          setTimeout(() => {
            formMessage.classList.add('hidden')
          }, 5000)
        }, 1000)
      }
    })
  }

  // Smooth scrolling for anchor links
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      e.preventDefault()
      
      const targetId = this.getAttribute('href')
      if (targetId === '#') return
      
      const targetElement = document.querySelector(targetId)
      if (targetElement) {
        targetElement.scrollIntoView({
          behavior: 'smooth'
        })
      }
    })
  })
})
