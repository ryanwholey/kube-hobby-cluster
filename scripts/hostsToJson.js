const execSync = require('child_process').execSync

function main() {
  const out = execSync(`AWS_PROFILE=ryan aws ec2 describe-instances | jq '.Reservations[] | .Instances[] | select(.State.Name == "running") | .Tags[0].Value, .PublicIpAddress '`
  ).toString('utf8')

  return out.split('\n').reduce((map, _item, index, collection) => {
    let item = _item.replace(/\"/g, '')

    if (!item || Number.isInteger(+item[0]))  {
      return map
    } else {
      let type
      if (item.startsWith('kube-master')) {
        type = 'masters'
      } else if (item.startsWith('kube-worker')) {
        type = 'workers'
      } else if (item.startsWith('load-balancer')) {
        type = 'loadbalancers'
      }

      map[type] = [
        ...map[type],
        {
          ansible_user: 'ubuntu',
          name: item,
          ansible_host: collection[index + 1].replace(/\"/g,''),
        }
      ]
      return map
    }
  }, {
    masters: [],
    workers: [],
    loadbalancers: [],
  })
}

module.exports = main